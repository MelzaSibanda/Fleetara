from rest_framework import serializers
from .models import Horse, Trailer


class HorseSerializer(serializers.ModelSerializer):
    service_due      = serializers.BooleanField(read_only=True)
    km_until_service = serializers.IntegerField(read_only=True)

    class Meta:
        model  = Horse
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class TrailerSerializer(serializers.ModelSerializer):
    service_due = serializers.BooleanField(read_only=True)

    class Meta:
        model  = Trailer
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']
