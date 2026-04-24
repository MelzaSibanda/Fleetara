from django.db import models


class Horse(models.Model):

    STATUS_CHOICES = [
        ('active',      'Active'),
        ('inactive',    'Inactive'),
        ('maintenance', 'In Maintenance'),
    ]

    registration_number = models.CharField(max_length=50, unique=True)
    make                = models.CharField(max_length=100)
    model               = models.CharField(max_length=100)
    year                = models.IntegerField()
    color               = models.CharField(max_length=50, blank=True)
    vin_number          = models.CharField(max_length=100, blank=True)

    license_expiry    = models.DateField()
    insurance_expiry  = models.DateField()
    roadworthy_expiry = models.DateField(null=True, blank=True)

    odometer             = models.IntegerField(default=0)
    service_interval_km  = models.IntegerField(default=20000)
    last_service_km      = models.IntegerField(default=0)
    next_service_km      = models.IntegerField(default=20000)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes  = models.TextField(blank=True)

    photo = models.URLField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.registration_number} — {self.make} {self.model}'

    @property
    def km_until_service(self):
        return self.next_service_km - self.odometer

    @property
    def service_due(self):
        return self.km_until_service <= 1000


class Trailer(models.Model):

    TYPE_CHOICES = [
        ('flatbed',      'Flatbed'),
        ('refrigerated', 'Refrigerated'),
        ('tanker',       'Tanker'),
        ('curtainsider', 'Curtainsider'),
        ('skeletal',     'Skeletal'),
        ('other',        'Other'),
    ]

    STATUS_CHOICES = [
        ('active',      'Active'),
        ('inactive',    'Inactive'),
        ('maintenance', 'In Maintenance'),
    ]

    registration_number = models.CharField(max_length=50, unique=True)
    trailer_type        = models.CharField(max_length=20, choices=TYPE_CHOICES)
    make                = models.CharField(max_length=100, blank=True)
    year                = models.IntegerField(null=True, blank=True)
    capacity_tons       = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    license_expiry    = models.DateField()
    insurance_expiry  = models.DateField()
    roadworthy_expiry = models.DateField(null=True, blank=True)

    odometer            = models.IntegerField(default=0)
    service_interval_km = models.IntegerField(default=20000)
    last_service_km     = models.IntegerField(default=0)
    next_service_km     = models.IntegerField(default=20000)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes  = models.TextField(blank=True)

    photo = models.URLField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.registration_number} ({self.trailer_type})'

    @property
    def service_due(self):
        return (self.next_service_km - self.odometer) <= 1000
