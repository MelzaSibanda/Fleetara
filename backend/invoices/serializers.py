from rest_framework import serializers
from .models import Invoice


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Invoice
        fields = '__all__'
        read_only_fields = ['id', 'tax_amount', 'total', 'created_at', 'updated_at']
