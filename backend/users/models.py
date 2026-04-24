from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):

    ROLE_CHOICES = [
        ('owner',         'Owner'),
        ('admin',         'Admin'),
        ('fleet_manager', 'Fleet Manager'),
        ('driver',        'Driver'),
    ]

    role  = models.CharField(max_length=20, choices=ROLE_CHOICES, default='driver')
    phone = models.CharField(max_length=20, blank=True)

    profile_photo = models.URLField(blank=True)

    license_number = models.CharField(max_length=50, blank=True)
    license_expiry = models.DateField(null=True, blank=True)

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.get_full_name()} ({self.role})'

    @property
    def is_driver(self):
        return self.role == 'driver'

    @property
    def is_owner(self):
        return self.role == 'owner'

    @property
    def is_fleet_manager(self):
        return self.role == 'fleet_manager'
