from rest_framework import generics
from .models       import Tyre
from .serializers  import TyreSerializer
from utils.permissions import IsFleetManager


class TyreListCreateView(generics.ListCreateAPIView):
    serializer_class   = TyreSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = Tyre.objects.all().order_by('vehicle_type')

        horse_id = self.request.query_params.get('horse_id')
        if horse_id:
            queryset = queryset.filter(horse_id=horse_id)

        trailer_id = self.request.query_params.get('trailer_id')
        if trailer_id:
            queryset = queryset.filter(trailer_id=trailer_id)

        condition = self.request.query_params.get('condition')
        if condition:
            queryset = queryset.filter(condition=condition)

        return queryset


class TyreDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = TyreSerializer
    permission_classes = [IsFleetManager]
    queryset           = Tyre.objects.all()
