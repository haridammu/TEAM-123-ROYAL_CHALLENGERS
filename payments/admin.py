from django.contrib import admin
from .models import SubscriptionPlan, UserSubscription, Payment

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'duration_days', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name', 'description')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(UserSubscription)
class UserSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan', 'start_date', 'end_date', 'is_active', 'created_at')
    list_filter = ('plan', 'is_active', 'start_date', 'end_date', 'created_at')
    search_fields = ('user__username', 'user__email', 'plan__name')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'currency', 'status', 'payment_method', 'payment_date')
    list_filter = ('status', 'payment_method', 'currency', 'payment_date')
    search_fields = ('user__username', 'user__email', 'transaction_id')
    readonly_fields = ('payment_date', 'updated_at')