from django.urls import path
from . import views

urlpatterns = [
    path('',          views.ServiceListCreateView.as_view(), name='service_list'),
    path('<int:pk>/', views.ServiceDetailView.as_view(),     name='service_detail'),
    path('upcoming/', views.UpcomingServicesView.as_view(),  name='upcoming_services'),
]
