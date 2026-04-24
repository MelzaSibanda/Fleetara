from rest_framework import serializers
from .models import Tyre


class TyreSerializer(serializers.ModelSerializer):
    km_used = serializers.IntegerField(read_only=True)

    class Meta:
        model  = Tyre
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']
