from django.urls import path
from . import views

urlpatterns = [
    path('',            views.FuelEntryListCreateView.as_view(), name='fuel_list'),
    path('<int:pk>/',   views.FuelEntryDetailView.as_view(),     name='fuel_detail'),
    path('analytics/',  views.FuelAnalyticsView.as_view(),       name='fuel_analytics'),
]
