# Secure Code Execution Architecture

## Overview
This document describes a secure architecture for executing user-submitted code using a backend service that can handle any programming language safely.

## Architecture Components

### 1. Flutter Frontend
- Code editor interface
- Language selection
- Code submission to backend
- Output display

### 2. Backend Execution Service
- Secure code execution environment
- Language-specific runners
- Resource limiting and monitoring
- Result returning to frontend

### 3. Isolation Layer
- Docker containers for each execution
- Time limits (e.g., 30 seconds)
- Memory limits (e.g., 256MB)
- Network isolation

## Implementation Approach

### Backend Service (Django/Python Example)

```python
import docker
import tempfile
import os
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

# Language configurations
LANGUAGE_CONFIGS = {
    'python': {
        'image': 'python:3.9-alpine',
        'extension': '.py',
        'command': lambda file_name: ['python', file_name]
    },
    'javascript': {
        'image': 'node:alpine',
        'extension': '.js',
        'command': lambda file_name: ['node', file_name]
    },
    'java': {
        'image': 'openjdk:11-jdk-slim',
        'extension': '.java',
        'command': lambda file_name: ['javac', file_name, '&&', 'java', 'Main']
    }
}

@csrf_exempt
def execute_code(request):
    try:
        data = json.loads(request.body)
        language = data.get('language')
        code = data.get('code')
        
        if language not in LANGUAGE_CONFIGS:
            return JsonResponse({'error': 'Unsupported language'}, status=400)
        
        config = LANGUAGE_CONFIGS[language]
        
        # Create Docker client
        client = docker.from_env()
        
        # Create temporary file
        file_name = f"temp_{uuid.uuid4().hex}{config['extension']}"
        
        # Execute code in container
        try:
            result = client.containers.run(
                config['image'],
                config['command'](file_name),
                volumes={temp_dir: {'bind': '/workspace', 'mode': 'rw'}},
                working_dir='/workspace',
                mem_limit='256m',
                timeout=30,
                remove=True,
                stdout=True,
                stderr=True,
                detach=False
            )
            
            output = result.decode('utf-8') if isinstance(result, bytes) else str(result)
            return JsonResponse({'output': output})
            
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

### Flutter Service Integration

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  final String baseUrl = 'https://your-backend-service.com/api';
  final String token;

  CodeExecutionService({required this.token});

  Future<Map<String, dynamic>> executeCode({
    required String language,
    required String code,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/code/execute/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'language': language,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Execution failed: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
```

## Security Considerations

### 1. Container Isolation
- Each execution runs in a separate Docker container
- Containers are destroyed after execution
- No persistent state between executions

### 2. Resource Limits
- CPU time limit (30 seconds)
- Memory limit (256MB)
- No network access by default
- File system isolation

### 3. Code Scanning
- Basic syntax validation
- Malicious pattern detection
- Size limitations

## Benefits of This Approach

1. **True Execution**: Actually runs user code
2. **Multi-Language**: Supports any language with appropriate Docker images
3. **Secure**: Isolated execution environment
4. **Scalable**: Can handle multiple concurrent executions
5. **Flexible**: Easy to add new languages

## Implementation Requirements

### Backend Server
- Docker daemon running
- Appropriate Docker images for each language
- HTTPS endpoint for secure communication
- Authentication system

### Flutter App
- Internet permission
- HTTP client library
- Error handling for network issues

## Deployment Options

### 1. Self-Hosted
- Run your own backend server
- Full control over execution environment
- Higher infrastructure costs

### 2. Cloud Services
- Use services like Repl.it API, JDoodle, or HackerEarth
- Lower setup complexity
- Pay-per-use pricing

### 3. Hybrid Approach
- Simple simulations locally
- Complex execution on backend
- Best user experience

## Conclusion

While Flutter cannot directly execute system commands like Python's subprocess, integrating with a secure backend execution service provides the most robust solution for running user-submitted code. This approach offers security, flexibility, and true code execution capabilities.