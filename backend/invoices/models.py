from django.db import models
from django.conf import settings


class Invoice(models.Model):

    TYPE_CHOICES = [
        ('receivable', 'Receivable — Client owes us'),
        ('payable',    'Payable — We owe supplier'),
    ]

    STATUS_CHOICES = [
        ('draft',     'Draft'),
        ('sent',      'Sent'),
        ('paid',      'Paid'),
        ('overdue',   'Overdue'),
        ('cancelled', 'Cancelled'),
    ]

    CATEGORY_CHOICES = [
        ('trip',    'Trip / Freight'),
        ('fuel',    'Fuel'),
        ('service', 'Vehicle Service'),
        ('repair',  'Repair'),
        ('tyre',    'Tyres'),
        ('other',   'Other'),
    ]

    invoice_number = models.CharField(max_length=50, unique=True)
    invoice_type   = models.CharField(max_length=15, choices=TYPE_CHOICES)
    category       = models.CharField(max_length=10, choices=CATEGORY_CHOICES, default='trip')

    trip    = models.ForeignKey('trips.Trip',              null=True, blank=True, on_delete=models.SET_NULL, related_name='invoices')
    service = models.ForeignKey('services.ServiceRecord',  null=True, blank=True, on_delete=models.SET_NULL, related_name='invoices')

    party_name    = models.CharField(max_length=200)
    party_email   = models.EmailField(blank=True)
    party_phone   = models.CharField(max_length=20, blank=True)
    party_address = models.TextField(blank=True)

    subtotal    = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_percent = models.DecimalField(max_digits=5,  decimal_places=2, default=15)
    tax_amount  = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total       = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    issue_date = models.DateField()
    due_date   = models.DateField()
    paid_date  = models.DateField(null=True, blank=True)

    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='draft')

    document_url = models.URLField(blank=True)

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='invoices_created'
    )

    notes      = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.invoice_number} — {self.party_name} — R{self.total}'

    def save(self, *args, **kwargs):
        self.tax_amount = round(self.subtotal * self.tax_percent / 100, 2)
        self.total      = round(self.subtotal + self.tax_amount, 2)
        super().save(*args, **kwargs)
