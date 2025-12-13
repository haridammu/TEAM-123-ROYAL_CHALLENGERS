# Code Execution Module for LMS

This module provides secure, multi-language code execution for the LMS backend using Django and Django REST Framework.

## Features
- Supports Python, JavaScript, Dart, C, C++, and Java
- Authenticated API endpoint for code execution
- Handles compilation (C, C++, Java) and runtime (all languages)
- Timeout and error handling for safe execution

## Directory Structure
```
code_execution/
├── models.py         # CodeSnippet model
├── serializers.py    # CodeSnippetSerializer
├── urls.py           # API route for code execution
├── views.py          # Main code execution logic
```

## API Endpoint
- `POST /api/code/execute/`
  - Requires authentication (Token)
  - Request body: `{ "language": "python", "code": "print('hi')" }`
  - Response: `{ "output": "hi\n" }` or `{ "error": "..." }`

## Setup
1. Ensure `code_execution` is included in your Django project and `INSTALLED_APPS`.
2. Add the endpoint to your main `urls.py`:
   ```python
   path("api/code/", include("code_execution.urls")),
   ```
3. Install dependencies (see root `requirements.txt`).
4. Run migrations:
   ```bash
   python manage.py makemigrations code_execution
   python manage.py migrate
   ```

## Security Notes
- Only authenticated users can execute code.
- Each execution is sandboxed in a temporary directory.
- Timeout is enforced to prevent abuse.

## Example Usage
See `test_code_execution.py` in the project root for API usage examples.

---
For full LMS setup, see the main `README.md`.
