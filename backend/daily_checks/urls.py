from django.urls import path
from . import views

urlpatterns = [
    path('',          views.DailyCheckListCreateView.as_view(), name='daily_check_list'),
    path('<int:pk>/', views.DailyCheckDetailView.as_view(),     name='daily_check_detail'),
]
