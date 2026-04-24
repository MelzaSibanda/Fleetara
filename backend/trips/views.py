from rest_framework import generics, status
from rest_framework.views    import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models      import Trip
from .serializers import TripSerializer, TripDetailSerializer
from utils.permissions import IsFleetManager, IsDriverOrManager


class TripListCreateView(generics.ListCreateAPIView):
    serializer_class   = TripSerializer
    permission_classes = [IsDriverOrManager]

    def get_queryset(self):
        user     = self.request.user
        queryset = Trip.objects.all().order_by('-scheduled_start')

        if user.role == 'driver':
            queryset = queryset.filter(driver=user)

        trip_status = self.request.query_params.get('status')
        if trip_status:
            queryset = queryset.filter(status=trip_status)

        driver_id = self.request.query_params.get('driver_id')
        if driver_id and user.role != 'driver':
            queryset = queryset.filter(driver_id=driver_id)

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == 'driver':
            serializer.save(driver=user)
        else:
            serializer.save()


class TripDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsDriverOrManager]

    def get_serializer_class(self):
        if self.request.method == 'GET':
            return TripDetailSerializer
        return TripSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == 'driver':
            return Trip.objects.filter(driver=user)
        return Trip.objects.all()


class TripStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        from django.utils import timezone
        try:
            trip = Trip.objects.get(pk=pk)
        except Trip.DoesNotExist:
            return Response({'error': 'Trip not found.'}, status=404)

        new_status = request.data.get('status')
        if new_status not in ['in_progress', 'completed', 'cancelled']:
            return Response({'error': 'Invalid status.'}, status=400)

        if new_status == 'in_progress':
            trip.actual_start = timezone.now()
        if new_status == 'completed':
            trip.actual_end = timezone.now()

        trip.status = new_status
        trip.save()

        return Response(TripSerializer(trip).data)


class ActiveTripsView(generics.ListAPIView):
    serializer_class   = TripDetailSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        return Trip.objects.filter(status='in_progress').order_by('-actual_start')
