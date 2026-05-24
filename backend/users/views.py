import requests as http_requests

from rest_framework          import generics, status
from rest_framework.views    import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

from .models       import User
from .serializers  import (
    RegisterSerializer, LoginSerializer,
    UserSerializer, ChangePasswordSerializer
)
from utils.permissions import IsOwnerOrAdmin, IsFleetManager

FIREBASE_API_KEY = 'AIzaSyDM-P5zR2V5jmh7GRivF6pjQ-LGwC0W6dc'


def _verify_firebase_token(id_token):
    """Verify a Firebase ID token via the Identity Toolkit REST API."""
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={FIREBASE_API_KEY}'
    resp = http_requests.post(url, json={'idToken': id_token}, timeout=10)
    if not resp.ok:
        msg = resp.json().get('error', {}).get('message', 'Token verification failed')
        raise ValueError(msg)
    users = resp.json().get('users', [])
    if not users:
        raise ValueError('No user found for this token')
    u = users[0]
    return {
        'uid':   u['localId'],
        'email': u.get('email', ''),
        'name':  u.get('displayName', ''),
    }


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user    = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'user':    UserSerializer(user).data,
                'refresh': str(refresh),
                'access':  str(refresh.access_token),
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user    = serializer.validated_data['user']
            refresh = RefreshToken.for_user(user)
            return Response({
                'user':    UserSerializer(user).data,
                'refresh': str(refresh),
                'access':  str(refresh.access_token),
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data['refresh']
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'})
        except Exception:
            return Response({'error': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(
            request.user, data=request.data, partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={'request': request}
        )
        if serializer.is_valid():
            request.user.set_password(serializer.validated_data['new_password'])
            request.user.save()
            return Response({'message': 'Password changed successfully.'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserListView(generics.ListAPIView):
    serializer_class   = UserSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = User.objects.all().order_by('first_name')
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role)
        return queryset


class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = UserSerializer
    permission_classes = [IsOwnerOrAdmin]
    queryset           = User.objects.all()


class FirebaseAuthView(APIView):
    """
    Exchange a Firebase ID token for Django JWT tokens.
    Accepts: { id_token, role?, first_name?, last_name?, phone? }
    Returns: { user, access, refresh }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')
        if not id_token:
            return Response({'error': 'id_token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            decoded = _verify_firebase_token(id_token)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': f'Token verification failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

        uid        = decoded['uid']
        email      = decoded.get('email', '')
        name       = decoded.get('name', '')
        first_name = request.data.get('first_name') or (name.split()[0] if name else '')
        last_name  = request.data.get('last_name')  or (' '.join(name.split()[1:]) if len(name.split()) > 1 else '')
        role       = request.data.get('role', 'driver')
        phone      = request.data.get('phone', '')

        valid_roles = [r[0] for r in User.ROLE_CHOICES]
        if role not in valid_roles:
            role = 'driver'

        user, created = User.objects.get_or_create(
            username=uid,
            defaults={
                'email':      email,
                'first_name': first_name,
                'last_name':  last_name,
                'role':       role,
                'phone':      phone,
            },
        )

        # On subsequent logins, keep email and name in sync
        if not created:
            updated = False
            if email and user.email != email:
                user.email = email
                updated = True
            if first_name and not user.first_name:
                user.first_name = first_name
                updated = True
            if last_name and not user.last_name:
                user.last_name = last_name
                updated = True
            if updated:
                user.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'user':    UserSerializer(user).data,
            'refresh': str(refresh),
            'access':  str(refresh.access_token),
        }, status=status.HTTP_200_OK)
