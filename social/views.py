from django.shortcuts import render
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Follow, Connection, Post, Comment, Achievement, Leaderboard
from .serializers import FollowSerializer, ConnectionSerializer, PostSerializer, CommentSerializer, AchievementSerializer, LeaderboardSerializer
from authentication.models import User

# Social App Root Endpoint
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def social_root(request):
    """
    Root endpoint for social API that lists available endpoints
    """
    return Response({
        'message': 'Social API endpoints',
        'endpoints': {
            'posts': '/api/social/posts/',
            'achievements': '/api/social/achievements/',
            'leaderboard': '/api/social/leaderboard/',
            'comments': '/api/social/comments/'
        }
    })

# Posts Views
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def posts_list_create(request):
    if request.method == 'GET':
        posts = Post.objects.all()
        serializer = PostSerializer(posts, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = PostSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(author=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_like(request, pk):
    try:
        post = Post.objects.get(pk=pk)
        if request.user in post.likes.all():
            post.likes.remove(request.user)
            message = "Post unliked"
        else:
            post.likes.add(request.user)
            message = "Post liked"
        return Response({"message": message}, status=status.HTTP_200_OK)
    except Post.DoesNotExist:
        return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_unlike(request, pk):
    try:
        post = Post.objects.get(pk=pk)
        if request.user in post.likes.all():
            post.likes.remove(request.user)
        return Response({"message": "Post unliked"}, status=status.HTTP_200_OK)
    except Post.DoesNotExist:
        return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)

# Comments Views
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def comments_list_create(request):
    if request.method == 'GET':
        comments = Comment.objects.all()
        serializer = CommentSerializer(comments, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = CommentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(author=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Achievements Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def achievements_list(request):
    user_id = request.query_params.get('user', None)
    if user_id:
        achievements = Achievement.objects.filter(user_id=user_id)
    else:
        achievements = Achievement.objects.all()
    
    serializer = AchievementSerializer(achievements, many=True)
    return Response(serializer.data)

# Leaderboard Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def leaderboard_list(request):
    leaderboard = Leaderboard.objects.all()
    serializer = LeaderboardSerializer(leaderboard, many=True)
    return Response(serializer.data)