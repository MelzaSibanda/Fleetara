from rest_framework import generics, status
from rest_framework.views    import APIView
from rest_framework.response import Response
from django.db.models        import Sum, Avg

from .models      import FuelEntry
from .serializers import FuelEntrySerializer
from utils.permissions import IsDriverOrManager, IsFleetManager


class FuelEntryListCreateView(generics.ListCreateAPIView):
    serializer_class   = FuelEntrySerializer
    permission_classes = [IsDriverOrManager]

    def get_queryset(self):
        user     = self.request.user
        queryset = FuelEntry.objects.all().order_by('-created_at')

        if user.role == 'driver':
            queryset = queryset.filter(entered_by=user)

        trip_id = self.request.query_params.get('trip_id')
        if trip_id:
            queryset = queryset.filter(trip_id=trip_id)

        horse_id = self.request.query_params.get('horse_id')
        if horse_id:
            queryset = queryset.filter(horse_id=horse_id)

        return queryset

    def perform_create(self, serializer):
        serializer.save(entered_by=self.request.user)


class FuelEntryDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = FuelEntrySerializer
    permission_classes = [IsFleetManager]
    queryset           = FuelEntry.objects.all()


class FuelAnalyticsView(APIView):
    permission_classes = [IsFleetManager]

    def get(self, request):
        queryset = FuelEntry.objects.all()

        horse_id = request.query_params.get('horse_id')
        if horse_id:
            queryset = queryset.filter(horse_id=horse_id)

        totals = queryset.aggregate(
            total_liters = Sum('liters'),
            total_cost   = Sum('cost'),
            avg_ppl      = Avg('price_per_liter'),
        )

        return Response({
            'total_liters':        totals['total_liters'] or 0,
            'total_cost':          totals['total_cost']   or 0,
            'avg_price_per_liter': round(totals['avg_ppl'] or 0, 2),
            'total_fill_ups':      queryset.count(),
        })
