from django.urls import path
from rest_framework.routers import DefaultRouter
from . import views

urlpatterns = [
    path('', views.quiz_list, name='quiz_list'),
    path('<int:pk>/', views.quiz_detail, name='quiz_detail'),
    path('attempts/start/', views.start_quiz_attempt, name='start_quiz_attempt'),
    path('attempts/<int:attempt_id>/complete/', views.complete_quiz_attempt, name='complete_quiz_attempt'),
    path('attempts/<int:attempt_id>/submit-answer/', views.submit_answer, name='submit_answer'),
    path('<int:quiz_id>/questions/', views.quiz_questions, name='quiz_questions'),
    path('questions/<int:question_id>/choices/', views.question_choices, name='question_choices'),
]