import 'package:flutter/material.dart';
import 'package:lms_app/services/websocket_service.dart';

class CollaborationScreen extends StatefulWidget {
  final int userId;
  final String? token;
  final int projectId;
  final String projectName;

  const CollaborationScreen({
    super.key,
    required this.userId,
    this.token,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  late WebSocketService _websocketService;
  bool _isConnected = false;
  String _errorMessage = '';
  String _documentContent = '';
  List<Map<String, dynamic>> _collaborators = [];
  final TextEditingController _documentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _websocketService = WebSocketService();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _documentController.dispose();
    _websocketService.disconnect();
    super.dispose();
  }

  Future<void> _connectToWebSocket() async {
    try {
      await _websocketService.connect(
        token: widget.token,
        onMessageReceived: _handleWebSocketMessage,
        onConnectionClosed: _handleWebSocketDisconnect,
      );

      // Join the collaboration session
      _websocketService.sendMessage({
        'type': 'join_collaboration',
        'project_id': widget.projectId,
        'user_id': widget.userId,
        'username': 'User ${widget.userId}',
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to collaboration session: $e';
      });
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final messageType = message['type'];

    if (messageType == 'document_update') {
      setState(() {
        _documentContent = message['content'];
        _documentController.text = _documentContent;
      });
    } else if (messageType == 'user_joined') {
      final user = {
        'id': message['user_id'],
        'name': message['username'],
        'color': _getUserColor(message['user_id']),
      };

      setState(() {
        _collaborators.add(user);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${message['username']} joined the collaboration'),
        ),
      );
    } else if (messageType == 'user_left') {
      setState(() {
        _collaborators.removeWhere((user) => user['id'] == message['user_id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${message['username']} left the collaboration'),
        ),
      );
    } else if (messageType == 'cursor_position') {
      // Handle cursor position updates
      // In a real implementation, you would show other users' cursors
    }
  }

  void _handleWebSocketDisconnect() {
    setState(() {
      _isConnected = false;
    });

    // Try to reconnect
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _connectToWebSocket();
      }
    });
  }

  Color _getUserColor(int userId) {
    // Generate a consistent color based on user ID
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[userId % colors.length];
  }

  void _onDocumentChanged() {
    if (_websocketService.isConnected) {
      // Send document update to all collaborators
      _websocketService.sendMessage({
        'type': 'document_update',
        'project_id': widget.projectId,
        'content': _documentController.text,
        'user_id': widget.userId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collaborating on: ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Icon(
            _isConnected ? Icons.circle : Icons.circle_outlined,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body:
          _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _connectToWebSocket,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Collaborators bar
                  if (_collaborators.isNotEmpty)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('Collaborators: '),
                          const SizedBox(width: 10),
                          Wrap(
                            spacing: 8,
                            children:
                                _collaborators.map((collaborator) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: collaborator['color'],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(collaborator['name']),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // Document editor
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _documentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Start collaborating on your project...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _onDocumentChanged(),
                      ),
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isConnected ? _onDocumentChanged : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Share project functionality
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Export project functionality
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
