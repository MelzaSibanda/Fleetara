from rest_framework import serializers
from .models import DailyCheck


class DailyCheckSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.get_full_name', read_only=True)
    horse_reg   = serializers.CharField(source='horse.registration_number', read_only=True)

    class Meta:
        model  = DailyCheck
        fields = '__all__'
        read_only_fields = ['id', 'driver', 'check_date', 'created_at']
