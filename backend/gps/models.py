from django.db import models
from django.conf import settings


class GPSLocation(models.Model):

    trip   = models.ForeignKey('trips.Trip',             on_delete=models.CASCADE, related_name='gps_locations')
    driver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='gps_locations')

    latitude  = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    altitude  = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    speed_kmh = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    heading   = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    accuracy  = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Trip #{self.trip.id} — {self.latitude}, {self.longitude} @ {self.timestamp}'

    class Meta:
        ordering = ['-timestamp']
        indexes  = [
            models.Index(fields=['trip', 'timestamp']),
        ]
