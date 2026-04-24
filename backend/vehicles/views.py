from rest_framework import generics, status
from rest_framework.views    import APIView
from rest_framework.response import Response
from django.utils            import timezone
from datetime                import timedelta

from .models       import Horse, Trailer
from .serializers  import HorseSerializer, TrailerSerializer
from utils.permissions import IsFleetManager, IsDriverOrManager


class HorseListCreateView(generics.ListCreateAPIView):
    serializer_class   = HorseSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = Horse.objects.all().order_by('registration_number')
        status   = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status)
        return queryset


class HorseDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = HorseSerializer
    permission_classes = [IsFleetManager]
    queryset           = Horse.objects.all()


class TrailerListCreateView(generics.ListCreateAPIView):
    serializer_class   = TrailerSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = Trailer.objects.all().order_by('registration_number')
        status   = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status)
        return queryset


class TrailerDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = TrailerSerializer
    permission_classes = [IsFleetManager]
    queryset           = Trailer.objects.all()


class VehicleAlertsView(APIView):
    permission_classes = [IsFleetManager]

    def get(self, request):
        soon = timezone.now().date() + timedelta(days=30)

        horses_expiring = Horse.objects.filter(
            license_expiry__lte=soon
        ) | Horse.objects.filter(
            insurance_expiry__lte=soon
        )

        trailers_expiring = Trailer.objects.filter(
            license_expiry__lte=soon
        ) | Trailer.objects.filter(
            insurance_expiry__lte=soon
        )

        service_due_horses   = [h for h in Horse.objects.all()   if h.service_due]
        service_due_trailers = [t for t in Trailer.objects.all() if t.service_due]

        return Response({
            'expiring_documents': {
                'horses':   HorseSerializer(horses_expiring.distinct(),    many=True).data,
                'trailers': TrailerSerializer(trailers_expiring.distinct(), many=True).data,
            },
            'service_due': {
                'horses':   HorseSerializer(service_due_horses,    many=True).data,
                'trailers': TrailerSerializer(service_due_trailers, many=True).data,
            }
        })
