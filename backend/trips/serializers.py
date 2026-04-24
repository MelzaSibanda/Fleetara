from rest_framework import serializers
from .models import Trip
from users.serializers    import UserSerializer
from vehicles.serializers import HorseSerializer, TrailerSerializer


class TripSerializer(serializers.ModelSerializer):
    actual_distance_km = serializers.IntegerField(read_only=True)
    duration_hours     = serializers.FloatField(read_only=True)

    class Meta:
        model  = Trip
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class TripDetailSerializer(TripSerializer):
    driver  = UserSerializer(read_only=True)
    horse   = HorseSerializer(read_only=True)
    trailer = TrailerSerializer(read_only=True)
