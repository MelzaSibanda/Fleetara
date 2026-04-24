from rest_framework import serializers
from .models import FuelEntry


class FuelEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model  = FuelEntry
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'price_per_liter']

    def validate_liters(self, value):
        if value <= 0:
            raise serializers.ValidationError('Liters must be greater than zero.')
        return value

    def validate_cost(self, value):
        if value <= 0:
            raise serializers.ValidationError('Cost must be greater than zero.')
        return value
