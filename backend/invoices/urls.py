from django.urls import path
from . import views

urlpatterns = [
    path('',                views.InvoiceListCreateView.as_view(), name='invoice_list'),
    path('<int:pk>/',       views.InvoiceDetailView.as_view(),     name='invoice_detail'),
    path('summary/',        views.FinancialSummaryView.as_view(),  name='financial_summary'),
    path('company-profile/',views.CompanyProfileView.as_view(),    name='company_profile'),
    path('statement/',      views.StatementView.as_view(),         name='statement'),
]
