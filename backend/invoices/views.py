from rest_framework import generics
from rest_framework.views    import APIView
from rest_framework.response import Response
from django.db.models        import Sum

from .models      import Invoice, CompanyProfile
from .serializers import InvoiceSerializer, CompanyProfileSerializer
from utils.permissions import IsOwnerOrAdmin, IsFleetManager


class InvoiceListCreateView(generics.ListCreateAPIView):
    serializer_class   = InvoiceSerializer
    permission_classes = [IsFleetManager]

    def get_queryset(self):
        queryset = Invoice.objects.all().order_by('-issue_date')

        invoice_type = self.request.query_params.get('type')
        if invoice_type:
            queryset = queryset.filter(invoice_type=invoice_type)

        invoice_status = self.request.query_params.get('status')
        if invoice_status:
            queryset = queryset.filter(status=invoice_status)

        return queryset

    def perform_create(self, serializer):
        last = Invoice.objects.order_by('-id').first()
        next_num = (last.id + 1) if last else 1
        invoice_number = f'FLT-{str(next_num).zfill(5)}'
        serializer.save(
            created_by=self.request.user,
            invoice_number=invoice_number
        )


class InvoiceDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class   = InvoiceSerializer
    permission_classes = [IsFleetManager]
    queryset           = Invoice.objects.all()


class CompanyProfileView(APIView):
    permission_classes = [IsFleetManager]

    def get(self, request):
        profile, _ = CompanyProfile.objects.get_or_create(pk=1)
        return Response(CompanyProfileSerializer(profile).data)

    def put(self, request):
        profile, _ = CompanyProfile.objects.get_or_create(pk=1)
        serializer = CompanyProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


class FinancialSummaryView(APIView):
    permission_classes = [IsOwnerOrAdmin]

    def get(self, request):
        receivables = Invoice.objects.filter(invoice_type='receivable')
        payables    = Invoice.objects.filter(invoice_type='payable')

        total_receivable = receivables.aggregate(t=Sum('total'))['t'] or 0
        total_payable    = payables.aggregate(t=Sum('total'))['t']    or 0
        total_paid_in    = receivables.filter(status='paid').aggregate(t=Sum('total'))['t'] or 0
        total_paid_out   = payables.filter(status='paid').aggregate(t=Sum('total'))['t']    or 0
        outstanding      = receivables.filter(status__in=['sent', 'overdue']).aggregate(t=Sum('total'))['t'] or 0

        return Response({
            'total_receivable': total_receivable,
            'total_payable':    total_payable,
            'total_paid_in':    total_paid_in,
            'total_paid_out':   total_paid_out,
            'outstanding':      outstanding,
            'net_profit':       round(float(total_paid_in) - float(total_paid_out), 2),
        })
