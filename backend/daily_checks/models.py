from django.db import models
from django.conf import settings


class DailyCheck(models.Model):
    STATUS_CHOICES = [
        ('pass',         'Pass'),
        ('minor_issue',  'Minor Issue'),
        ('critical',     'Critical Issue'),
    ]

    driver  = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='daily_checks',
        limit_choices_to={'role': 'driver'},
    )
    horse   = models.ForeignKey('vehicles.Horse',   on_delete=models.PROTECT, related_name='daily_checks')
    trailer = models.ForeignKey('vehicles.Trailer', on_delete=models.PROTECT, null=True, blank=True, related_name='daily_checks')
    trip    = models.ForeignKey('trips.Trip',        on_delete=models.SET_NULL, null=True, blank=True, related_name='daily_checks')

    # Horse — engine
    oil_level       = models.BooleanField(default=False)
    coolant_level   = models.BooleanField(default=False)
    no_engine_leaks = models.BooleanField(default=False)

    # Horse — wheels
    tyre_pressure  = models.BooleanField(default=False)
    tyre_condition = models.BooleanField(default=False)
    wheel_nuts     = models.BooleanField(default=False)

    # Horse — brakes
    brake_response = models.BooleanField(default=False)
    air_pressure   = models.BooleanField(default=False)

    # Horse — lights
    headlights   = models.BooleanField(default=False)
    indicators   = models.BooleanField(default=False)
    brake_lights = models.BooleanField(default=False)

    # Horse — safety
    fire_extinguisher    = models.BooleanField(default=False)
    reflective_triangles = models.BooleanField(default=False)
    seatbelt             = models.BooleanField(default=False)

    # Trailer
    trailer_tyres      = models.BooleanField(default=False)
    coupling_system    = models.BooleanField(default=False)
    trailer_lights     = models.BooleanField(default=False)
    cargo_locking      = models.BooleanField(default=False)
    trailer_suspension = models.BooleanField(default=False)

    overall_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pass')
    notes          = models.TextField(blank=True)
    odometer       = models.IntegerField(null=True, blank=True)

    check_date = models.DateField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Check #{self.id} — {self.driver} — {self.check_date} — {self.overall_status}'
