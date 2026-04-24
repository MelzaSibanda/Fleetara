from rest_framework import generics
from rest_framework.views    import APIView
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta

from .models      import ServiceRecord
from .serializers import ServiceRecordSerializer
from utils.permissions import IsFleetManager


class ServiceListCreateView(generics.ListCreateAPIView):
    serializer_class   = ServiceRecordSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = ServiceRecord.objects.all().order_by('-scheduled_date')

        status = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status)

        horse_id = self.request.query_params.get('horse_id')
        if horse_id:
            queryset = queryset.filter(horse_id=horse_id)

        return queryset

    def perform_create(self, serializer):
        serializer.save(recorded_by=self.request.user)


class ServiceDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = ServiceRecordSerializer
    permission_classes = [IsFleetManager]
    queryset           = ServiceRecord.objects.all()


class UpcomingServicesView(APIView):
    permission_classes = [IsFleetManager]

    def get(self, request):
        today = timezone.now().date()
        soon  = today + timedelta(days=30)
        upcoming = ServiceRecord.objects.filter(
            scheduled_date__range=[today, soon],
            status='scheduled'
        ).order_by('scheduled_date')
        return Response(ServiceRecordSerializer(upcoming, many=True).data)
