from django.urls import path
from . import views

urlpatterns = [
    path('',          views.TyreListCreateView.as_view(), name='tyre_list'),
    path('<int:pk>/', views.TyreDetailView.as_view(),     name='tyre_detail'),
]
