from django.db import models
from django.conf import settings


class ServiceRecord(models.Model):

    SERVICE_TYPE_CHOICES = [
        ('minor',      'Minor Service'),
        ('major',      'Major Service'),
        ('oil_change', 'Oil Change'),
        ('brake',      'Brake Service'),
        ('clutch',     'Clutch'),
        ('gearbox',    'Gearbox'),
        ('diff',       'Differential'),
        ('electrical', 'Electrical'),
        ('body',       'Body Work'),
        ('other',      'Other'),
    ]

    STATUS_CHOICES = [
        ('scheduled',   'Scheduled'),
        ('in_progress', 'In Progress'),
        ('completed',   'Completed'),
    ]

    horse   = models.ForeignKey('vehicles.Horse',   null=True, blank=True, on_delete=models.CASCADE, related_name='services')
    trailer = models.ForeignKey('vehicles.Trailer', null=True, blank=True, on_delete=models.CASCADE, related_name='services')

    service_type = models.CharField(max_length=20, choices=SERVICE_TYPE_CHOICES)
    description  = models.TextField()

    workshop_name    = models.CharField(max_length=200, blank=True)
    workshop_contact = models.CharField(max_length=100, blank=True)
    technician       = models.CharField(max_length=100, blank=True)

    odometer_at_service = models.IntegerField()
    next_service_km     = models.IntegerField(null=True, blank=True)

    parts_cost  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    labour_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_cost  = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    scheduled_date = models.DateField()
    completed_date = models.DateField(null=True, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')

    document_url = models.URLField(blank=True)

    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='services_recorded'
    )

    notes      = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        vehicle = self.horse or self.trailer
        return f'{self.service_type} — {vehicle} on {self.scheduled_date}'

    def save(self, *args, **kwargs):
        self.total_cost = self.parts_cost + self.labour_cost
        super().save(*args, **kwargs)
