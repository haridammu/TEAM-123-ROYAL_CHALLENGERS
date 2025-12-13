# Code Execution Backend Setup Guide

## Overview
This guide explains how to set up the backend service for the code execution feature in the LMS application. The backend handles secure compilation and execution of user-submitted code in multiple programming languages.

## Prerequisites
- Python 3.8+
- Django 4.0+
- Docker (recommended for isolation)
- System packages for supported languages:
  - Python 3.x
  - Node.js 14+
  - OpenJDK 11+
  - GCC (for C/C++)
  - Dart SDK

## Installation Steps

### 1. Install System Dependencies

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y python3 nodejs openjdk-11-jdk gcc g++ dart
```

#### CentOS/RHEL:
```bash
sudo yum install -y python3 nodejs java-11-openjdk gcc gcc-c++ dart
```

#### Windows:
Download and install the respective SDKs from their official websites.

### 2. Set Up Django Project

1. Create a new Django app:
```bash
python manage.py startapp code_execution
```

2. Add to `INSTALLED_APPS` in `settings.py`:
```python
INSTALLED_APPS = [
    # ... other apps
    'code_execution',
]
```

3. Create the model in `models.py`:
```python
from django.db import models
from django.contrib.auth.models import User

class CodeSnippet(models.Model):
    LANGUAGE_CHOICES = [
        ('python', 'Python'),
        ('java', 'Java'),
        ('c', 'C'),
        ('cpp', 'C++'),
        ('javascript', 'JavaScript'),
        ('dart', 'Dart'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    language = models.CharField(max_length=20, choices=LANGUAGE_CHOICES)
    title = models.CharField(max_length=100, blank=True)
    code = models.TextField()
    output = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} ({self.language})"
```

4. Create and apply migrations:
```bash
python manage.py makemigrations
python manage.py migrate
```

### 3. Implement Serializers

Create `serializers.py`:
```python
from rest_framework import serializers
from .models import CodeSnippet

class CodeSnippetSerializer(serializers.ModelSerializer):
    class Meta:
        model = CodeSnippet
        fields = ['id', 'language', 'title', 'code', 'output', 'created_at', 'updated_at']
        read_only_fields = ['user', 'output', 'created_at', 'updated_at']
```

### 4. Implement Views

Create `views.py`:
```python
import os
import subprocess
import tempfile
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import CodeSnippet
from .serializers import CodeSnippetSerializer
import json

# Language configurations
LANGUAGE_CONFIGS = {
    'python': {
        'extension': '.py',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['python3', file_path]
    },
    'javascript': {
        'extension': '.js',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['node', file_path]
    },
    'dart': {
        'extension': '.dart',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['dart', file_path]
    },
    'c': {
        'extension': '.c',
        'compile_cmd': lambda source_path, output_path: ['gcc', source_path, '-o', output_path],
        'run_cmd': lambda output_path: [output_path]
    },
    'cpp': {
        'extension': '.cpp',
        'compile_cmd': lambda source_path, output_path: ['g++', source_path, '-o', output_path],
        'run_cmd': lambda output_path: [output_path]
    },
    'java': {
        'extension': '.java',
        'compile_cmd': lambda source_path, _: ['javac', source_path],
        'run_cmd': lambda _: ['java', 'Main']
    }
}

@csrf_exempt
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def execute_code(request):
    try:
        data = json.loads(request.body)
        language = data.get('language')
        code = data.get('code')
        
        if not language or not code:
            return JsonResponse({'error': 'Language and code are required'}, status=400)
        
        if language not in LANGUAGE_CONFIGS:
            return JsonResponse({'error': f'Unsupported language: {language}'}, status=400)
        
        config = LANGUAGE_CONFIGS[language]
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            file_name = f"temp_{uuid.uuid4().hex}{config['extension']}"
            file_path = os.path.join(temp_dir, file_name)
            
            # Write code to file
            with open(file_path, 'w') as f:
                f.write(code)
            
            # Compile if needed
            if config['compile_cmd']:
                try:
                    if language == 'java':
                        compile_process = subprocess.run(
                            config['compile_cmd'](file_path, None),
                            cwd=temp_dir,
                            capture_output=True,
                            text=True,
                            timeout=30
                        )
                    else:
                        output_name = 'a.out' if language in ['c', 'cpp'] else file_path.replace(config['extension'], '')
                        compile_process = subprocess.run(
                            config['compile_cmd'](file_path, output_name),
                            cwd=temp_dir,
                            capture_output=True,
                            text=True,
                            timeout=30
                        )
                    
                    if compile_process.returncode != 0:
                        return JsonResponse({
                            'error': f'Compilation failed:\\n{compile_process.stderr}'
                        }, status=400)
                except subprocess.TimeoutExpired:
                    return JsonResponse({'error': 'Compilation timed out'}, status=400)
            
            # Execute code
            try:
                if language == 'java':
                    run_process = subprocess.run(
                        config['run_cmd'](None),
                        cwd=temp_dir,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                elif language in ['c', 'cpp']:
                    output_path = os.path.join(temp_dir, 'a.out')
                    run_process = subprocess.run(
                        config['run_cmd'](output_path),
                        cwd=temp_dir,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                else:
                    run_process = subprocess.run(
                        config['run_cmd'](file_path),
                        cwd=temp_dir,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                
                output = run_process.stdout
                if run_process.stderr:
                    output += f"\\nErrors:\\n{run_process.stderr}"
                    
                return JsonResponse({'output': output})
                
            except subprocess.TimeoutExpired:
                return JsonResponse({'error': 'Code execution timed out'}, status=400)
                
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_snippets(request):
    snippets = CodeSnippet.objects.filter(user=request.user).order_by('-created_at')
    serializer = CodeSnippetSerializer(snippets, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_snippet(request):
    serializer = CodeSnippetSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(user=request.user)
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)
```

### 5. Configure URLs

Create `urls.py` in the code_execution app:
```python
from django.urls import path
from . import views

urlpatterns = [
    path('execute/', views.execute_code, name='execute_code'),
    path('snippets/', views.get_user_snippets, name='get_user_snippets'),
    path('snippets/save/', views.save_snippet, name='save_snippet'),
]
```

Include in main `urls.py`:
```python
from django.urls import path, include

urlpatterns = [
    # ... other URLs
    path('api/code/', include('code_execution.urls')),
]
```

### 6. Security Considerations

1. **Timeout Protection**: All compilation and execution processes have a 30-second timeout
2. **Isolation**: Code runs in temporary directories with limited permissions
3. **Resource Limits**: Consider adding memory and CPU limits in production
4. **Input Validation**: Validate all inputs before processing
5. **Authentication**: All endpoints require authentication

### 7. Testing the Service

Start the Django development server:
```bash
python manage.py runserver
```

Test with curl:
```bash
curl -X POST http://127.0.0.1:8000/api/code/execute/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token YOUR_AUTH_TOKEN" \
  -d '{"language": "python", "code": "print(\"Hello, World!\")"}'
```

Expected response:
```json
{
  "output": "Hello, World!\n"
}
```

## Deployment Recommendations

1. **Containerization**: Use Docker to isolate the execution environment
2. **Resource Monitoring**: Monitor CPU and memory usage
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **Logging**: Add comprehensive logging for debugging
5. **Backup**: Regular backups of the database
6. **SSL**: Use HTTPS in production

## Troubleshooting

### Common Issues

1. **"Command not found"**: Ensure all required compilers/interpreters are installed
2. **Permission denied**: Check file permissions in temporary directories
3. **Timeout errors**: Optimize code or increase timeout limits (not recommended)
4. **Compilation errors**: Validate code syntax before execution

### Debugging Tips

1. Check Django logs for errors
2. Test each language compiler individually
3. Verify authentication token is valid
4. Ensure the database is properly migrated

## Conclusion

This backend service provides a secure and scalable solution for executing user-submitted code. With proper configuration and security measures, it enables a rich code execution experience in the LMS application.