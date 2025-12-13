from django.contrib import admin
from .models import Quiz, Question, Choice, UserQuizAttempt, UserAnswer

@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'lesson', 'passing_score', 'created_at')
    list_filter = ('course', 'lesson', 'created_at')
    search_fields = ('title', 'description', 'course__title')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ('text', 'quiz', 'question_type', 'points', 'order')
    list_filter = ('quiz', 'question_type', 'created_at')
    search_fields = ('text', 'quiz__title')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Choice)
class ChoiceAdmin(admin.ModelAdmin):
    list_display = ('text', 'question', 'is_correct', 'order')
    list_filter = ('question__quiz', 'is_correct')
    search_fields = ('text', 'question__text')

@admin.register(UserQuizAttempt)
class UserQuizAttemptAdmin(admin.ModelAdmin):
    list_display = ('user', 'quiz', 'score', 'passed', 'started_at', 'completed_at')
    list_filter = ('quiz', 'passed', 'started_at', 'completed_at')
    search_fields = ('user__username', 'user__email', 'quiz__title')
    readonly_fields = ('started_at', 'completed_at', 'time_taken')

@admin.register(UserAnswer)
class UserAnswerAdmin(admin.ModelAdmin):
    list_display = ('attempt', 'question', 'is_correct', 'points_awarded')
    list_filter = ('is_correct', 'question__quiz')
    search_fields = ('attempt__user__username', 'question__text')