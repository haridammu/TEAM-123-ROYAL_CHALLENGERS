# AI Chat Integration with Perplexity API

## Overview
This document explains how to integrate the Perplexity AI chat functionality into the LMS application. The integration provides users with an AI assistant that can help with educational questions, course recommendations, and study tips.

## Components

### 1. AIService
Handles communication with the Perplexity API:
- Located at: `lib/services/ai_service.dart`
- Manages API requests and responses
- Uses the `llama-3.1-sonar-small-128k-online` model

### 2. ChatService
Manages conversation history and message flow:
- Located at: `lib/services/chat_service.dart`
- Maintains chat history
- Coordinates between UI and AI service

### 3. ChatMessage Model
Represents individual chat messages:
- Located at: `lib/models/chat_message.dart`
- Supports user, AI, and system message types

### 4. UI Components
Provides the chat interface:
- `ChatMessageWidget` - Displays individual messages
- `AIChatScreen` - Main chat interface

## Setup Instructions

### 1. Obtain Perplexity API Key
1. Sign up at [Perplexity AI](https://www.perplexity.ai/)
2. Navigate to the API section
3. Generate an API key

### 2. Configure API Key
Replace the placeholder in `lib/utils/constants.dart`:
```
static const String perplexityApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
static const String grokApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### 3. Access the AI Chat
Users can access the AI chat through the dashboard:
1. Open the navigation drawer
2. Tap on "AI Assistant"

## Features

- Real-time conversation with AI assistant
- Message history persistence during session
- Error handling for API communication issues
- Responsive UI with message timestamps
- Support for educational queries

## Customization

### System Prompt
The default system prompt can be modified in `lib/utils/constants.dart` to change the AI's behavior and personality.

### AI Model
The AI model can be changed by updating the `aiModel` constant in `lib/utils/constants.dart`.

## Error Handling

The integration includes error handling for:
- Network connectivity issues
- API rate limiting
- Invalid API keys
- Server-side errors

Users will see appropriate error messages when issues occur.

## Dependencies

The integration requires the following packages:
- `http` - For API communication
- `uuid` - For generating unique message IDs

These are automatically included when running `flutter pub get`.

## Testing

To test the AI chat functionality:
1. Ensure you have a valid Perplexity API key
2. Run the application
3. Navigate to the AI Chat screen
4. Send a test message
5. Verify the AI response is displayed correctly

## Troubleshooting

### No Response from AI
- Check API key validity
- Verify network connectivity
- Confirm Perplexity API status

### Authentication Errors
- Ensure API key is correctly configured
- Check for typos in the key

### Slow Responses
- Perplexity API may be experiencing high traffic
- Check internet connection speed