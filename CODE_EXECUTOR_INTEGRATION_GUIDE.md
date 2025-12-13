# Code Executor Integration Guide

## Overview
This guide explains how to integrate the code execution service with the LMS Flutter application.

## Architecture

### Components
1. **Flutter Frontend**: User interface for code editing and execution
2. **Django Backend**: Secure code execution service
3. **Authentication Bridge**: Converts Supabase tokens to Django tokens

## How It Works

### 1. Authentication Flow
1. User logs in with Supabase (Google or email/password)
2. Flutter app gets Supabase token from AuthService
3. CodeExecutionService exchanges Supabase token for Django token
4. Django token is used for all subsequent code execution requests

### 2. Code Execution Flow
1. User writes code in the editor
2. User selects language and clicks "Run"
3. Flutter sends code to Django backend with Django token
4. Django executes code in isolated environment
5. Results are returned to Flutter app

## Setup Instructions

### Backend Setup
1. Navigate to the code executor service directory:
   ```bash
   cd c:\Users\LENOVO\Lms\code_executor_service
   ```

2. Activate virtual environment:
   ```bash
   .\venv\Scripts\activate
   ```

3. Start the Django server:
   ```bash
   python manage.py runserver
   ```

### Frontend Integration
The Flutter app automatically handles:
- Token exchange with backend
- Code execution requests
- Error handling and user feedback

## Supported Languages
- Python
- JavaScript
- Java
- C
- C++
- Dart

## Security Features
- Process isolation using subprocess
- Execution timeout (30 seconds)
- Temporary file cleanup
- Token-based authentication
- Resource limiting

## Troubleshooting

### Common Issues

#### Authentication Failed
- Ensure Django server is running
- Check that the baseUrl in CodeExecutionService matches the Django server address
- Verify that the user has a valid Supabase token

#### Connection Refused
- Make sure the Django server is running on the correct port
- Check firewall settings
- Verify network connectivity

#### Code Execution Timeout
- Simplify the code to reduce execution time
- Check for infinite loops
- Optimize algorithms

## API Endpoints

### Authentication
- **POST** `/api/code/auth/` - Exchange Supabase token for Django token

### Code Execution
- **POST** `/api/code/execute/` - Execute code with specified language

### Snippets
- **GET** `/api/code/snippets/` - Get user's saved snippets
- **POST** `/api/code/snippets/save/` - Save a code snippet

## Testing

### Backend Testing
```bash
# Test authentication
curl -X POST http://127.0.0.1:8000/api/code/auth/ \
  -H "Content-Type: application/json" \
  -d '{"supabase_token": "test"}'

# Test code execution
curl -X POST http://127.0.0.1:8000/api/code/execute/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token YOUR_DJANGO_TOKEN" \
  -d '{"language": "python", "code": "print(\"Hello, World!\")"}'
```

## Future Enhancements
- Docker containerization for better isolation
- Enhanced resource monitoring
- Rate limiting
- Advanced code analysis
- Syntax highlighting in editor

## Conclusion
This integration provides a secure, scalable solution for executing user code within the LMS application. The separation of concerns between authentication and code execution ensures both security and usability.