from rest_framework import serializers
from .models import SubscriptionPlan, UserSubscription, Payment
from authentication.models import User
from authentication.serializers import UserSerializer

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class UserSubscriptionSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    plan_details = SubscriptionPlanSerializer(source='plan', read_only=True)
    
    class Meta:
        model = UserSubscription
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class PaymentSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Payment
        fields = '__all__'
        read_only_fields = ('payment_date', 'updated_at',)