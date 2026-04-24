from rest_framework import serializers
from .models import Repair


class RepairSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Repair
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at', 'reported_at']
