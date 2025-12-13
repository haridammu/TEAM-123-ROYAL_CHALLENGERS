from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import SubscriptionPlan, UserSubscription, Payment
from .serializers import SubscriptionPlanSerializer, UserSubscriptionSerializer, PaymentSerializer

# Subscription Plans Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def subscription_plans_list(request):
    plans = SubscriptionPlan.objects.filter(is_active=True)
    serializer = SubscriptionPlanSerializer(plans, many=True)
    return Response(serializer.data)

# User Subscriptions Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_subscriptions_list(request):
    subscriptions = UserSubscription.objects.all()
    serializer = UserSubscriptionSerializer(subscriptions, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def subscribe_to_plan(request):
    serializer = UserSubscriptionSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)