import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/chat_message_widget.dart';
import '../services/ai_chat_service.dart';
import '../services/groq_service.dart';
import '../utils/constants.dart';

class AIChatScreen extends StatefulWidget {
  final String? apiKey;
  final int userId; // Add this line to properly declare the userId parameter

  const AIChatScreen({super.key, this.apiKey, required this.userId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late AIChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _showApiKeyInput = false;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    print('=== AI CHAT SCREEN INIT ===');
    _currentApiKey = widget.apiKey;
    _initializeChatService();
  }

  void _initializeChatService() {
    print('Initializing chat service...');
    try {
      // Use provided API key or default
      final apiKey = _currentApiKey ?? AppConstants.groqApiKey;
      print('Using API key length: ${apiKey.length}');
      print(
        'API key starts with: ${apiKey.substring(0, min(10, apiKey.length))}...',
      );
      print('API key is empty: ${apiKey.isEmpty}');
      print('API key present: ${apiKey.isNotEmpty}');

if (apiKey.isEmpty) {
  throw Exception('Please set a valid Groq API key in settings');
}

      // Check if the API key looks valid (not empty and starts with '_')
      if (apiKey.isEmpty |print('API key present: ${apiKey.isNotEmpty}');

if (apiKey.isEmpty) {
  throw Exception('Please set a valid Groq API key in settings');
}

        print('WARNING: Using invalid API key format');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please set a valid Groq API key in settings (must start with _)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final aiService = GroqService(apiKey: apiKey);
      _chatService = AIChatService(aiService: aiService);
      print('Chat service initialized successfully');
    } catch (e, stackTrace) {
      // Handle initialization error
      print('Error initializing AI service: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing AI service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    print('Disposing AI chat screen...');
    _textController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Set API key and reinitialize service
  void _setApiKey() {
    print('Setting new API key...');
    final newApiKey = _apiKeyController.text.trim();

    if (newApiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid API key'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _currentApiKey = newApiKey;
      _showApiKeyInput = false;
      _initializeChatService();
    });

    // Add a system message about the API key update
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Send a message to the AI
  Future<void> _sendMessage() async {
    print('Sending message...');
    if (_textController.text.trim().isEmpty || _isSending) {
      print('Message is empty or already sending');
      return;
    }

    final message = _textController.text.trim();
    print('Message content length: ${message.length}');
    _textController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Send the message to the AI
      print('Calling chat service to send message...');
      await _chatService.sendMessageToAI(message);
      print('Message sent successfully');

      // Scroll to the bottom of the chat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, stackTrace) {
      print('=== AI CHAT SCREEN ERROR ===');
      print('Error sending message: $e');
      print('Stack trace: $stackTrace');

      // Show an error message
      if (mounted) {
        String errorMessage = e.toString();
        // Truncate long error messages
        if (errorMessage.length > 200) {
          errorMessage = '${errorMessage.substring(0, 200)}...';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building AI chat screen...');
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showApiKeyInput = !_showApiKeyInput;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // API Key input (shown when settings icon is pressed)
          if (_showApiKeyInput)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your Groq API key',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _setApiKey,
                    child: const Text('Set'),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatService.messages.length,
              itemBuilder: (context, index) {
                final message = _chatService.messages[index];
                return ChatMessageWidget(message: message);
              },
            ),
          ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon:
                      _isSending
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
