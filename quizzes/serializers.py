from rest_framework import serializers
from .models import Quiz, Question, Choice, UserQuizAttempt, UserAnswer
from authentication.models import User
from authentication.serializers import UserSerializer
from courses.models import Course, Lesson
from courses.serializers import CourseSerializer, LessonSerializer

class QuizSerializer(serializers.ModelSerializer):
    course_details = CourseSerializer(source='course', read_only=True)
    lesson_details = LessonSerializer(source='lesson', read_only=True)
    
    class Meta:
        model = Quiz
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class QuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class ChoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Choice
        fields = '__all__'

class UserQuizAttemptSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    quiz_details = QuizSerializer(source='quiz', read_only=True)
    
    class Meta:
        model = UserQuizAttempt
        fields = '__all__'
        read_only_fields = ('started_at', 'completed_at', 'time_taken',)

class UserAnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAnswer
        fields = '__all__'