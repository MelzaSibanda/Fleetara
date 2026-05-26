from rest_framework import serializers
from .models import Invoice, CompanyProfile


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Invoice
        fields = '__all__'
        read_only_fields = ['id', 'invoice_number', 'tax_amount', 'total', 'created_at', 'updated_at', 'created_by']


class CompanyProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model  = CompanyProfile
        fields = '__all__'
