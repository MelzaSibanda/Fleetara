from django.db import models
from django.conf import settings


class Trip(models.Model):

    STATUS_CHOICES = [
        ('scheduled',   'Scheduled'),
        ('in_progress', 'In Progress'),
        ('completed',   'Completed'),
        ('cancelled',   'Cancelled'),
    ]

    CARGO_TYPE_CHOICES = [
        ('general',    'General Freight'),
        ('perishable', 'Perishable'),
        ('hazardous',  'Hazardous'),
        ('oversized',  'Oversized'),
        ('bulk',       'Bulk'),
        ('other',      'Other'),
    ]

    driver  = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='trips',
        limit_choices_to={'role': 'driver'}
    )
    horse   = models.ForeignKey('vehicles.Horse',   on_delete=models.PROTECT, related_name='trips')
    trailer = models.ForeignKey('vehicles.Trailer', on_delete=models.PROTECT, related_name='trips')

    client_name    = models.CharField(max_length=200)
    client_contact = models.CharField(max_length=100, blank=True)
    client_phone   = models.CharField(max_length=20,  blank=True)

    origin      = models.CharField(max_length=200)
    destination = models.CharField(max_length=200)
    distance_km = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    cargo_description = models.TextField()
    cargo_type        = models.CharField(max_length=20, choices=CARGO_TYPE_CHOICES, default='general')
    cargo_weight_tons = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    waybill_number   = models.CharField(max_length=100, blank=True)
    waybill_document = models.URLField(blank=True)

    scheduled_start = models.DateTimeField()
    scheduled_end   = models.DateTimeField(null=True, blank=True)
    actual_start    = models.DateTimeField(null=True, blank=True)
    actual_end      = models.DateTimeField(null=True, blank=True)

    start_odometer = models.IntegerField(null=True, blank=True)
    end_odometer   = models.IntegerField(null=True, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    notes  = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'Trip #{self.id} — {self.origin} → {self.destination} ({self.status})'

    @property
    def actual_distance_km(self):
        if self.start_odometer and self.end_odometer:
            return self.end_odometer - self.start_odometer
        return None

    @property
    def duration_hours(self):
        if self.actual_start and self.actual_end:
            delta = self.actual_end - self.actual_start
            return round(delta.total_seconds() / 3600, 2)
        return None
