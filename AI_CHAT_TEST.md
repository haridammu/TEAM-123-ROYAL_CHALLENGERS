# AI Chat Integration Test Guide

## Overview
This guide provides instructions for testing the AI chat integration with Perplexity API in the LMS application.

## Prerequisites
1. A valid Perplexity API key
2. Internet connectivity
3. The LMS application running successfully

## Test Steps

### 1. Accessing the AI Chat
1. Launch the LMS application
2. Navigate to the Dashboard
3. Tap on "AI Assistant" in the navigation drawer
4. Verify that the AI chat screen loads successfully

### 2. Setting Up the API Key
1. In the AI chat screen, tap the settings icon (gear icon) in the top right corner
2. Enter your Perplexity API key in the input field
3. Tap "Set" to save the API key
4. Verify that a success message appears

### 3. Sending a Test Message
1. Type a simple question in the message input field (e.g., "What is machine learning?")
2. Tap the send button or press enter
3. Wait for the AI response
4. Verify that:
   - The user message appears in the chat
   - The AI response appears in the chat
   - The response is relevant to the question

### 4. Testing Error Handling
1. Temporarily remove or invalidate your API key
2. Try sending a message
3. Verify that an appropriate error message is displayed
4. Correct the API key and try again

## Expected Results
- The AI chat screen should load without errors
- Messages should be sent and received successfully with a valid API key
- Proper error messages should be displayed for invalid API keys
- The chat history should persist during the session

## Troubleshooting
If you encounter issues:

1. **401 Authorization Error**:
   - Verify your API key is correct
   - Check that your Perplexity account has API access
   - Ensure the API key hasn't expired

2. **Network Errors**:
   - Check your internet connection
   - Verify that the Perplexity API endpoint is accessible

3. **No Response**:
   - Check the application logs for errors
   - Verify that the API key has sufficient quota

## Support
If you continue to experience issues after following this guide, please:
1. Check the application logs for detailed error messages
2. Refer to the PERPLEXITY_API_SETUP.md documentation
3. Contact the development team for assistance