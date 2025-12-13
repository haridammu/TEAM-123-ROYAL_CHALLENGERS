from django.urls import path
from rest_framework.routers import DefaultRouter
from . import views

urlpatterns = [
    path('', views.social_root, name='social_root'),
    path('posts/', views.posts_list_create, name='posts_list_create'),
    path('posts/<int:pk>/like/', views.post_like, name='post_like'),
    path('posts/<int:pk>/unlike/', views.post_unlike, name='post_unlike'),
    path('comments/', views.comments_list_create, name='comments_list_create'),
    path('achievements/', views.achievements_list, name='achievements_list'),
    path('leaderboard/', views.leaderboard_list, name='leaderboard_list'),
]