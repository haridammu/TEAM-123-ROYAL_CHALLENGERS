import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const ChatScreen({super.key, required this.userId, this.token});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService _chatService;
  List<PrivateChat> _chats = [];
  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedChatId;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(token: widget.token);
    _loadChats();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.getPrivateChats(widget.userId);
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages(int chatId) async {
    try {
      final messages = await _chatService.getPrivateMessages(chatId);
      setState(() {
        _messages = messages;
        _selectedChatId = chatId;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedChatId == null)
      return;

    try {
      await _chatService.sendPrivateMessage(
        chatId: _selectedChatId!,
        senderId: widget.userId,
        content: _messageController.text.trim(),
      );

      // Clear the input field
      _messageController.clear();

      // Reload messages
      _loadMessages(_selectedChatId!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadChats,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Row(
                children: [
                  // Chats list sidebar
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return ListTile(
                          title: Text(
                            chat.user1Id == widget.userId
                                ? 'User ${chat.user2Id}'
                                : 'User ${chat.user1Id}',
                          ),
                          selected: _selectedChatId == chat.id,
                          onTap: () => _loadMessages(chat.id),
                        );
                      },
                    ),
                  ),
                  // Messages area
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Messages list
                        Expanded(
                          child:
                              _selectedChatId == null
                                  ? const Center(
                                    child: Text(
                                      'Select a chat to start messaging',
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _messages.length,
                                    reverse:
                                        true, // Show newest messages at the bottom
                                    itemBuilder: (context, index) {
                                      final message =
                                          _messages.reversed.toList()[index];
                                      final isMe =
                                          message.senderId == widget.userId;

                                      return Align(
                                        alignment:
                                            isMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                isMe
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(message.content),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        // Message input
                        if (_selectedChatId != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message...',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _sendMessage,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
