from rest_framework import generics
from .models      import Repair
from .serializers import RepairSerializer
from utils.permissions import IsDriverOrManager, IsFleetManager


class RepairListCreateView(generics.ListCreateAPIView):
    serializer_class   = RepairSerializer
    permission_classes = [IsDriverOrManager]

    def get_queryset(self):
        queryset = Repair.objects.all().order_by('-created_at')

        priority = self.request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)

        status = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status)

        return queryset

    def perform_create(self, serializer):
        serializer.save(reported_by=self.request.user)


class RepairDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = RepairSerializer
    permission_classes = [IsFleetManager]
    queryset           = Repair.objects.all()
