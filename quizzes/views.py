from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Quiz, Question, Choice, UserQuizAttempt, UserAnswer
from .serializers import QuizSerializer, QuestionSerializer, ChoiceSerializer, UserQuizAttemptSerializer, UserAnswerSerializer

# Quizzes Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_list(request):
    """Get all quizzes"""
    quizzes = Quiz.objects.all()
    serializer = QuizSerializer(quizzes, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_detail(request, pk):
    try:
        quiz = Quiz.objects.get(pk=pk)
        serializer = QuizSerializer(quiz)
        return Response(serializer.data)
    except Quiz.DoesNotExist:
        return Response({"error": "Quiz not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_questions(request, quiz_id):
    """Get all questions for a specific quiz"""
    try:
        questions = Question.objects.filter(quiz_id=quiz_id)
        serializer = QuestionSerializer(questions, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def question_choices(request, question_id):
    """Get all choices for a specific question"""
    try:
        choices = Choice.objects.filter(question_id=question_id)
        serializer = ChoiceSerializer(choices, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

# Quiz Attempts Views
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_quiz_attempt(request):
    serializer = UserQuizAttemptSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def complete_quiz_attempt(request, attempt_id):
    """Complete a quiz attempt"""
    try:
        attempt = UserQuizAttempt.objects.get(id=attempt_id)
        attempt.completed_at = request.data.get('completed_at')
        attempt.save()
        serializer = UserQuizAttemptSerializer(attempt)
        return Response(serializer.data)
    except UserQuizAttempt.DoesNotExist:
        return Response({"error": "Quiz attempt not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_answer(request, attempt_id):
    """Submit an answer for a question in a quiz attempt"""
    try:
        data = request.data.copy()
        data['attempt'] = attempt_id
        serializer = UserAnswerSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)