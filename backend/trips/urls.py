from django.urls import path
from . import views

urlpatterns = [
    path('',               views.TripListCreateView.as_view(),   name='trip_list'),
    path('<int:pk>/',      views.TripDetailView.as_view(),       name='trip_detail'),
    path('<int:pk>/status/', views.TripStatusUpdateView.as_view(), name='trip_status'),
    path('active/',        views.ActiveTripsView.as_view(),      name='active_trips'),
]
