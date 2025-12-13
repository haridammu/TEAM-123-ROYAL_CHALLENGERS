# GROK API SETUP GUIDE

This document provides instructions for setting up the Grok API integration for the AI Assistant feature in the LMS application.

## Prerequisites

1. Grok API key from xAI
2. Valid internet connection
3. Flutter development environment

## Setup Instructions

### 1. Obtain Grok API Key

1. Visit the [xAI Developer Platform](https://docs.x.ai/docs/quickstart)
2. Sign in or create an account
3. Generate a new API key
4. Copy the API key for use in the application

### 2. Configure API Key in Application

In `lib/utils/constants.dart`:
```dart
   static const String grokApiKey = 'your_actual_api_key_here';
   static const String grokApiUrl = 'https://api.x.ai/v1/chat/completions';
```

Replace `'your_actual_api_key_here'` with your actual Grok API key.

### 3. Verify Integration

1. Launch the LMS application
2. Navigate to Dashboard → AI Assistant
3. Send a test message like "Hello, what is 2+2?"
4. Verify that you receive a response from the Grok AI

## Troubleshooting

### Common Issues

1. **API Key Not Working**: Verify the key is correct and has not expired
2. **Network Issues**: Verify internet connectivity
3. **Rate Limiting**: Wait before sending additional requests

### Debugging Steps

1. Check console output for detailed logs
2. Verify API key configuration
3. Test with simple messages first
4. Monitor network traffic if needed