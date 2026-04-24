from rest_framework import generics, status
from rest_framework.views    import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models      import GPSLocation
from .serializers import GPSLocationSerializer
from utils.permissions import IsFleetManager


class SendLocationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = GPSLocationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(driver=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TripLocationHistoryView(generics.ListAPIView):
    serializer_class   = GPSLocationSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        trip_id = self.kwargs['trip_id']
        return GPSLocation.objects.filter(trip_id=trip_id).order_by('timestamp')


class LiveLocationsView(APIView):
    permission_classes = [IsFleetManager]

    def get(self, request):
        from trips.models import Trip
        active_trips = Trip.objects.filter(status='in_progress')
        live_data = []

        for trip in active_trips:
            latest = GPSLocation.objects.filter(trip=trip).order_by('-timestamp').first()
            if latest:
                live_data.append({
                    'trip_id':     trip.id,
                    'driver':      trip.driver.get_full_name(),
                    'horse':       trip.horse.registration_number,
                    'origin':      trip.origin,
                    'destination': trip.destination,
                    'latitude':    latest.latitude,
                    'longitude':   latest.longitude,
                    'speed_kmh':   latest.speed_kmh,
                    'timestamp':   latest.timestamp,
                })

        return Response(live_data)
