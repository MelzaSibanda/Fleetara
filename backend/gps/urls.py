from django.urls import path
from . import views

urlpatterns = [
    path('location/',                   views.SendLocationView.as_view(),        name='send_location'),
    path('trip/<int:trip_id>/history/', views.TripLocationHistoryView.as_view(), name='location_history'),
    path('live/',                       views.LiveLocationsView.as_view(),       name='live_locations'),
]
