from django.db import models


class Tyre(models.Model):

    VEHICLE_TYPE_CHOICES = [
        ('horse',   'Horse'),
        ('trailer', 'Trailer'),
    ]

    POSITION_CHOICES = [
        ('steer_left',        'Steer Left'),
        ('steer_right',       'Steer Right'),
        ('drive_left_outer',  'Drive Left Outer'),
        ('drive_left_inner',  'Drive Left Inner'),
        ('drive_right_outer', 'Drive Right Outer'),
        ('drive_right_inner', 'Drive Right Inner'),
        ('trailer_1',         'Trailer Axle 1'),
        ('trailer_2',         'Trailer Axle 2'),
        ('trailer_3',         'Trailer Axle 3'),
        ('spare',             'Spare'),
    ]

    CONDITION_CHOICES = [
        ('good',     'Good'),
        ('worn',     'Worn'),
        ('critical', 'Critical — Replace Soon'),
        ('replaced', 'Replaced'),
    ]

    vehicle_type = models.CharField(max_length=10, choices=VEHICLE_TYPE_CHOICES)
    horse        = models.ForeignKey('vehicles.Horse',   null=True, blank=True, on_delete=models.SET_NULL, related_name='tyres')
    trailer      = models.ForeignKey('vehicles.Trailer', null=True, blank=True, on_delete=models.SET_NULL, related_name='tyres')

    serial_number = models.CharField(max_length=100, blank=True)
    brand         = models.CharField(max_length=100, blank=True)
    size          = models.CharField(max_length=50,  blank=True)
    position      = models.CharField(max_length=30,  choices=POSITION_CHOICES)

    installed_km  = models.IntegerField()
    replaced_km   = models.IntegerField(null=True, blank=True)
    km_lifespan   = models.IntegerField(default=120000)

    condition  = models.CharField(max_length=20, choices=CONDITION_CHOICES, default='good')
    notes      = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        vehicle = self.horse or self.trailer
        return f'Tyre — {vehicle} @ {self.position}'

    @property
    def km_used(self):
        if self.replaced_km:
            return self.replaced_km - self.installed_km
        return None
