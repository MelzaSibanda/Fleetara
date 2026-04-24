from django.urls import path
from . import views

urlpatterns = [
    path('',          views.RepairListCreateView.as_view(), name='repair_list'),
    path('<int:pk>/', views.RepairDetailView.as_view(),     name='repair_detail'),
]
