from django.contrib import admin
from .models import Follow, Connection, Post, Comment, Achievement, Leaderboard

@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ('follower', 'followed', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('follower__username', 'follower__email', 'followed__username', 'followed__email')

@admin.register(Connection)
class ConnectionAdmin(admin.ModelAdmin):
    list_display = ('requester', 'receiver', 'status', 'created_at', 'updated_at')
    list_filter = ('status', 'created_at', 'updated_at')
    search_fields = ('requester__username', 'requester__email', 'receiver__username', 'receiver__email')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ('author', 'content_preview', 'likes_count', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('author__username', 'author__email', 'content')
    readonly_fields = ('created_at', 'updated_at')
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content Preview'
    
    def likes_count(self, obj):
        return obj.likes.count()
    likes_count.short_description = 'Likes Count'

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ('post', 'author', 'content_preview', 'likes_count', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('author__username', 'author__email', 'content', 'post__content')
    readonly_fields = ('created_at', 'updated_at')
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 0 else ''
    content_preview.short_description = 'Content Preview'
    
    def likes_count(self, obj):
        return obj.likes.count()
    likes_count.short_description = 'Likes Count'

@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'earned_at')
    list_filter = ('earned_at',)
    search_fields = ('user__username', 'user__email', 'title', 'description')
    readonly_fields = ('earned_at',)

@admin.register(Leaderboard)
class LeaderboardAdmin(admin.ModelAdmin):
    list_display = ('user', 'points', 'rank', 'last_updated')
    list_filter = ('last_updated',)
    search_fields = ('user__username', 'user__email')
    readonly_fields = ('last_updated',)