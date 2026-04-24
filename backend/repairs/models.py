from django.db import models
from django.conf import settings


class Repair(models.Model):

    PRIORITY_CHOICES = [
        ('low',      'Low'),
        ('medium',   'Medium'),
        ('high',     'High'),
        ('critical', 'Critical — Off Road'),
    ]

    STATUS_CHOICES = [
        ('reported',    'Reported'),
        ('in_progress', 'In Progress'),
        ('completed',   'Completed'),
    ]

    horse   = models.ForeignKey('vehicles.Horse',   null=True, blank=True, on_delete=models.CASCADE, related_name='repairs')
    trailer = models.ForeignKey('vehicles.Trailer', null=True, blank=True, on_delete=models.CASCADE, related_name='repairs')

    trip = models.ForeignKey('trips.Trip', null=True, blank=True, on_delete=models.SET_NULL, related_name='repairs')

    reported_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='repairs_reported'
    )

    title       = models.CharField(max_length=200)
    description = models.TextField()
    priority    = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES,   default='reported')

    workshop_name = models.CharField(max_length=200, blank=True)
    repair_cost   = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    photos = models.TextField(blank=True)

    reported_at  = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    notes      = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        vehicle = self.horse or self.trailer
        return f'{self.priority.upper()} — {self.title} ({vehicle})'

    def photo_list(self):
        if self.photos:
            return self.photos.split(',')
        return []
