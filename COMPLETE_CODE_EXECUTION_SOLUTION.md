# Complete Code Execution Solution

## Overview
This document describes the complete implementation of a robust code execution solution that allows users to run programs in various programming languages directly from the LMS Flutter application.

## Architecture

### Components
1. **Flutter Frontend**: User interface for code editing and execution
2. **Django Backend**: Secure code execution service
3. **Language Runtimes**: Interpreters and compilers for supported languages
4. **Security Layer**: Process isolation and resource limiting

## Implementation Details

### 1. Flutter Frontend

#### CodeExecutionService
The Flutter service connects to the backend execution service:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  final String baseUrl = 'http://127.0.0.1:8000/api/code';
  final String token;

  CodeExecutionService({required this.token});

  Future<Map<String, dynamic>> executeCode({
    required String language,
    required String code,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/execute/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'language': language,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        return {
          'success': true,
          'data': jsonData,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to execute code: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: Unable to connect to code execution service',
      };
    }
  }
}
```

#### CodeEditorScreen
The UI component that allows users to write and execute code:

```dart
class CodeEditorScreen extends StatefulWidget {
  final dynamic userId;
  final String? token;

  const CodeEditorScreen({super.key, required this.userId, this.token});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  // Implementation details...
  
  Future<void> _executeCode() async {
    setState(() {
      _isRunning = true;
      _output = 'Running code...\n';
    });

    try {
      final result = await _codeService.executeCode(
        language: _selectedLanguage,
        code: _code,
      );

      if (result['success']) {
        final data = result['data'];
        setState(() {
          _output = data['output'] ?? 'No output';
          _isRunning = false;
        });
      } else {
        setState(() {
          _output = 'Error: ${result['error']}';
          _isRunning = false;
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
        _isRunning = false;
      });
    }
  }
}
```

### 2. Django Backend

#### Views Implementation
The backend uses subprocess and threading for secure code execution:

```python
import os
import subprocess
import tempfile
import threading
import json
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

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
    # ... other languages
}

def execute_with_timeout(cmd, cwd=None, timeout=30):
    """Execute a command with timeout"""
    try:
        process = subprocess.Popen(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        timer = threading.Timer(timeout, process.kill)
        try:
            timer.start()
            stdout, stderr = process.communicate()
        finally:
            timer.cancel()
            
        return process.returncode, stdout, stderr
    except Exception as e:
        return -1, '', str(e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def execute_code(request):
    try:
        data = json.loads(request.body)
        language = data.get('language')
        code = data.get('code')
        
        # Validation and execution logic...
        
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write code to file
            # Compile if needed
            # Execute with timeout
            # Return results
            
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

## Supported Languages

### 1. Python
- **Runtime**: Python 3.x
- **Execution**: Direct interpretation
- **Features**: Full Python syntax support

### 2. JavaScript
- **Runtime**: Node.js
- **Execution**: Direct interpretation
- **Features**: ES6+ support

### 3. Java
- **Compiler**: javac
- **Runtime**: JVM
- **Execution**: Compilation then execution
- **Requirements**: Main class must be named `Main`

### 4. C
- **Compiler**: GCC
- **Execution**: Compilation then execution
- **Features**: Standard C support

### 5. C++
- **Compiler**: G++
- **Execution**: Compilation then execution
- **Features**: Standard C++ support

### 6. Dart
- **Runtime**: Dart VM
- **Execution**: Direct interpretation
- **Features**: Dart 2.x support

## Security Features

### 1. Process Isolation
- Each execution runs in a separate subprocess
- Temporary directories for file isolation
- Automatic cleanup after execution

### 2. Resource Limiting
- **Time Limit**: 30 seconds per execution
- **Memory**: System-controlled limits
- **File System**: Read-only access to code files

### 3. Authentication
- Token-based authentication required
- User-specific execution quotas (optional)
- Rate limiting (recommended)

### 4. Error Handling
- Graceful handling of compilation errors
- Timeout protection
- Resource exhaustion prevention

## API Endpoints

### Execute Code
- **Endpoint**: `/api/code/execute/`
- **Method**: POST
- **Authentication**: Required (Token)
- **Request Body**:
  ```json
  {
    "language": "python",
    "code": "print('Hello, World!')"
  }
  ```
- **Response**:
  ```json
  {
    "output": "Hello, World!\n"
  }
  ```

## Sample Programs

### Python Example
```python
def fibonacci(n):
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)

for i in range(10):
    print(f"Fibonacci({i}) = {fibonacci(i)}")
```

### JavaScript Example
```javascript
function factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

console.log("Factorial calculations:");
for (let i = 1; i <= 10; i++) {
    console.log(`${i}! = ${factorial(i)}`);
}
```

### Java Example
```java
public class Main {
    public static int gcd(int a, int b) {
        if (b == 0) return a;
        return gcd(b, a % b);
    }
    
    public static void main(String[] args) {
        System.out.println("GCD calculations:");
        int[][] pairs = {{48, 18}, {100, 25}, {17, 13}};
        
        for (int[] pair : pairs) {
            System.out.println("GCD(" + pair[0] + ", " + pair[1] + ") = " + gcd(pair[0], pair[1]));
        }
    }
}
```

## Deployment

### Local Development
1. Install system dependencies
2. Set up Django project
3. Run development server: `python manage.py runserver`
4. Test with Flutter app

### Production Deployment
1. Use Docker for process isolation
2. Implement rate limiting
3. Set up HTTPS
4. Monitor resource usage
5. Regular security updates

## Testing

### Unit Tests
```python
def test_python_execution():
    code = "print('Hello, World!')"
    result = execute_code_internal('python', code)
    assert 'Hello, World!' in result['output']
```

### Integration Tests
```dart
test('Python code execution', () async {
  final service = CodeExecutionService(token: 'test-token');
  final result = await service.executeCode(
    language: 'python',
    code: 'print("Hello, World!")',
  );
  expect(result['success'], true);
  expect(result['data']['output'], contains('Hello, World!'));
});
```

## Performance Considerations

### Concurrency
- Each execution is independent
- System resources limit concurrent executions
- Consider queuing for high-volume applications

### Optimization
- Cache frequently used interpreters
- Pre-warm language runtimes
- Monitor execution times

## Troubleshooting

### Common Issues
1. **"Command not found"**: Missing language runtime
2. **Timeout errors**: Infinite loops or heavy computations
3. **Permission errors**: File system restrictions
4. **Memory errors**: Resource exhaustion

### Debugging Steps
1. Verify language runtimes are installed
2. Check authentication tokens
3. Review Django logs
4. Test with simple programs

## Future Enhancements

### 1. Enhanced Security
- Docker containerization
- Advanced resource monitoring
- Sandboxing technologies

### 2. Improved Features
- Code snippet saving/loading
- Syntax highlighting
- Auto-completion
- Collaborative editing

### 3. Language Support
- Additional programming languages
- Version-specific runtimes
- Library/package management

## Conclusion

This complete code execution solution provides a robust, secure, and scalable way to execute user-submitted code in multiple programming languages. By combining a Flutter frontend with a Django backend and proper security measures, it offers an excellent learning experience for programming students while maintaining system integrity and performance.