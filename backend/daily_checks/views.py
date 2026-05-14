from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models      import DailyCheck
from .serializers import DailyCheckSerializer


class DailyCheckListCreateView(generics.ListCreateAPIView):
    serializer_class   = DailyCheckSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'driver':
            return DailyCheck.objects.filter(driver=user)
        return DailyCheck.objects.all().order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(driver=self.request.user)


class DailyCheckDetailView(generics.RetrieveAPIView):
    serializer_class   = DailyCheckSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'driver':
            return DailyCheck.objects.filter(driver=user)
        return DailyCheck.objects.all()
