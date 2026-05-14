from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),

    # API routes
    path('api/auth/',     include('users.urls')),
    path('api/vehicles/', include('vehicles.urls')),
    path('api/trips/',    include('trips.urls')),
    path('api/fuel/',     include('fuel.urls')),
    path('api/tyres/',    include('tyres.urls')),
    path('api/services/', include('services.urls')),
    path('api/repairs/',  include('repairs.urls')),
    path('api/invoices/', include('invoices.urls')),
    path('api/gps/',          include('gps.urls')),
    path('api/daily-checks/', include('daily_checks.urls')),
]
