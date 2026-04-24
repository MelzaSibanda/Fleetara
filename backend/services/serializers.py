from rest_framework import serializers
from .models import ServiceRecord


class ServiceRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ServiceRecord
        fields = '__all__'
        read_only_fields = ['id', 'total_cost', 'created_at', 'updated_at']
