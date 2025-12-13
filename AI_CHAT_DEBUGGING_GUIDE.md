# AI Chat Integration Debugging Guide

## Overview
This guide provides comprehensive debugging steps for the Perplexity AI chat integration in the LMS application.

## Common Issues and Solutions

### 1. Authorization Errors (401)
**Symptoms**: "Perplexity API authorization failed" error message  

**Debugging Steps**:
1. Check if API key is properly configured in `lib/utils/constants.dart`
2. Verify API key has not expired
3. Confirm API key has proper permissions
4. Test API key with direct curl request:
   ```bash
   curl -X POST https://api.perplexity.ai/chat/completions \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model": "sonar-reasoning-pro", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Hello"}]}'
   ```

### 2. Message Ordering Errors (400)
**Symptoms**: "After the (optional) system message(s), user or tool message(s) should alternate with assistant message(s)" error

**Debugging Steps**:
1. Check console logs for message formatting
2. Verify that messages alternate properly: system → user → assistant → user → assistant...
3. Ensure no duplicate messages are being sent
4. Confirm empty messages are filtered out

### 3. Rate Limiting Errors (429)
**Symptoms**: "Perplexity API rate limit exceeded" error message

**Debugging Steps**:
1. Implement request throttling in the application
2. Add retry logic with exponential backoff
3. Check Perplexity API documentation for rate limits
4. Monitor usage through Perplexity dashboard

### 4. Network/Connectivity Issues
**Symptoms**: Generic network errors or timeouts

**Debugging Steps**:
1. Verify internet connectivity
2. Check if firewall is blocking requests
3. Test API endpoint accessibility
4. Confirm DNS resolution is working

## Detailed Debugging Process

### Step 1: Enable Comprehensive Logging
The updated AI service includes extensive logging. When running the application, monitor the console output for detailed information about:
- API key being used (first 10 characters only)
- Request payload being sent
- Response received from API
- Error details and stack traces

### Step 2: Test with Simple Messages
Start with basic messages to isolate issues:
1. Send a simple "Hello" message
2. Send "What is 2+2?" 
3. Test conversation flow with history

### Step 3: Verify Constants Configuration
Check `lib/utils/constants.dart`:
```
static const String perplexityApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
static const String grokApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
static const String perplexityApiUrl = 'https://api.perplexity.ai/chat/completions';
static const String aiModel = 'sonar-reasoning-pro';
```

### Step 4: Test Direct API Call
Use the test script provided:
```bash
cd lms_app
dart ../test_ai_service.dart
```

### Step 5: Check Message History Construction
Monitor logs for:
- Proper alternation of user/assistant messages
- Correct role assignments
- Filtering of empty messages
- Proper system message placement

## Advanced Debugging Techniques

### 1. Network Traffic Analysis
Use tools like Charles Proxy or Wireshark to inspect:
- Actual HTTP requests being sent
- Request headers and body
- Response codes and content
- Timing and latency issues

### 2. API Key Validation
1. Log into Perplexity AI dashboard
2. Verify API key status
3. Check usage quotas
4. Confirm key permissions

### 3. Model Availability
Verify that the specified model is available:
- Check Perplexity documentation
- Test with alternative models
- Confirm model access with your account tier

## Error Code Reference

### 400 - Bad Request
- Invalid message formatting
- Malformed JSON
- Missing required fields

### 401 - Unauthorized
- Invalid or missing API key
- Expired API key
- Incorrect authorization header format

### 429 - Too Many Requests
- Rate limiting exceeded
- Concurrent requests limit reached

### 500 - Internal Server Error
- Perplexity API server issues
- Temporary service disruption

### Network Errors
- DNS resolution failures
- Connection timeouts
- SSL/TLS handshake issues

## Testing Checklist

### Basic Functionality
- [ ] API key properly configured
- [ ] Simple message sends and receives
- [ ] Error messages display correctly
- [ ] Loading indicators work

### Advanced Features
- [ ] Message history properly maintained
- [ ] Conversation flows naturally
- [ ] API key can be updated in-app
- [ ] Settings persist appropriately

### Error Handling
- [ ] 401 errors show clear guidance
- [ ] 429 errors suggest waiting
- [ ] Network errors provide helpful messages
- [ ] Unexpected errors don't crash app

## Troubleshooting Commands

### Check Dependencies
```bash
cd lms_app
flutter pub get
flutter pub outdated
```

### Run Tests
```bash
cd lms_app
flutter test
```

### Clean Build
```bash
cd lms_app
flutter clean
flutter pub get
flutter build
```

## Support Resources

### Perplexity Documentation
- [Perplexity API Documentation](https://docs.perplexity.ai/)
- [Model Specifications](https://docs.perplexity.ai/docs/model-cards)
- [Rate Limits](https://docs.perplexity.ai/docs/rate-limits)

### Community Support
- GitHub Issues
- Stack Overflow
- Discord Communities

### Contact Information
If issues persist after following this guide:
1. Capture complete console logs
2. Document steps to reproduce
3. Include error messages and stack traces
4. Provide environment information (OS, Flutter version, etc.)

## Preventive Measures

### Best Practices
1. Store API keys securely
2. Implement proper error handling
3. Add request retry logic
4. Monitor API usage
5. Keep dependencies updated

### Monitoring
1. Log all API requests
2. Track error rates
3. Monitor response times
4. Alert on rate limiting

This debugging guide should help identify and resolve most issues with the AI chat integration. If problems persist, please provide detailed logs and error messages for further assistance.