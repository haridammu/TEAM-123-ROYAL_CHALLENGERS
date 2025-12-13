from rest_framework import serializers
from .models import Follow, Connection, Post, Comment, Achievement, Leaderboard
from authentication.models import User
from authentication.serializers import UserSerializer

class FollowSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follow
        fields = '__all__'
        read_only_fields = ('created_at',)

class ConnectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Connection
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')

class PostSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')
    
    def get_likes_count(self, obj):
        return obj.likes.count()
    
    def get_comments_count(self, obj):
        return obj.comments.count()
        
    def get_image_url(self, obj):
        return obj.image_url
class CommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    likes_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Comment
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')
    
    def get_likes_count(self, obj):
        return obj.likes.count()

class AchievementSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Achievement
        fields = '__all__'
        read_only_fields = ('earned_at',)

class LeaderboardSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Leaderboard
        fields = '__all__'
        read_only_fields = ('last_updated',)