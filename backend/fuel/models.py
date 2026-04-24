from django.db import models
from django.conf import settings


class FuelEntry(models.Model):

    FUEL_TYPE_CHOICES = [
        ('diesel', 'Diesel'),
        ('petrol', 'Petrol'),
        ('adblue', 'AdBlue'),
    ]

    trip       = models.ForeignKey('trips.Trip',      on_delete=models.CASCADE, related_name='fuel_entries')
    horse      = models.ForeignKey('vehicles.Horse',  on_delete=models.PROTECT, related_name='fuel_entries')
    entered_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='fuel_entries'
    )

    fuel_type       = models.CharField(max_length=10, choices=FUEL_TYPE_CHOICES, default='diesel')
    liters          = models.DecimalField(max_digits=8, decimal_places=2)
    cost            = models.DecimalField(max_digits=10, decimal_places=2)
    price_per_liter = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    odometer      = models.IntegerField()
    fuel_station  = models.CharField(max_length=200, blank=True)
    location      = models.CharField(max_length=200, blank=True)

    fuel_slip_image = models.URLField(blank=True)

    notes      = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.liters}L — Trip #{self.trip.id} @ {self.odometer}km'

    def save(self, *args, **kwargs):
        if self.liters and self.cost:
            self.price_per_liter = round(self.cost / self.liters, 2)
        super().save(*args, **kwargs)
