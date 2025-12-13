from django.urls import path
from rest_framework.routers import DefaultRouter
from . import views

urlpatterns = [
    path('plans/', views.subscription_plans_list, name='subscription_plans_list'),
    path('subscriptions/', views.user_subscriptions_list, name='user_subscriptions_list'),
    path('subscribe/', views.subscribe_to_plan, name='subscribe_to_plan'),
]