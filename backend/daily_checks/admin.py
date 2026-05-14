from django.contrib import admin
from .models import DailyCheck

@admin.register(DailyCheck)
class DailyCheckAdmin(admin.ModelAdmin):
    list_display = ['id', 'driver', 'horse', 'overall_status', 'check_date']
    list_filter  = ['overall_status', 'check_date']
