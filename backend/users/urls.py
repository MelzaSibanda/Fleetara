from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Auth
    path('register/',       views.RegisterView.as_view(),       name='register'),
    path('login/',          views.LoginView.as_view(),          name='login'),
    path('logout/',         views.LogoutView.as_view(),         name='logout'),
    path('token/refresh/',  TokenRefreshView.as_view(),         name='token_refresh'),

    # Profile
    path('me/',             views.MeView.as_view(),             name='me'),
    path('me/password/',    views.ChangePasswordView.as_view(), name='change_password'),

    # User management
    path('users/',          views.UserListView.as_view(),       name='user_list'),
    path('users/<int:pk>/', views.UserDetailView.as_view(),     name='user_detail'),
]
