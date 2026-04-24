from django.urls import path
from . import views

urlpatterns = [
    path('horses/',            views.HorseListCreateView.as_view(),   name='horse_list'),
    path('horses/<int:pk>/',   views.HorseDetailView.as_view(),       name='horse_detail'),
    path('trailers/',          views.TrailerListCreateView.as_view(), name='trailer_list'),
    path('trailers/<int:pk>/', views.TrailerDetailView.as_view(),     name='trailer_detail'),
    path('alerts/',            views.VehicleAlertsView.as_view(),     name='vehicle_alerts'),
]
