from rest_framework import serializers
from .models import GPSLocation


class GPSLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model  = GPSLocation
        fields = '__all__'
        read_only_fields = ['id', 'timestamp']
