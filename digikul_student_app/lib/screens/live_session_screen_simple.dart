import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class LiveSessionScreenSimple extends StatefulWidget {
  final String sessionId;
  final String lectureId;
  final String lectureTitle;
  final String teacherName;

  const LiveSessionScreenSimple({
    super.key,
    required this.sessionId,
    required this.lectureId,
    required this.lectureTitle,
    required this.teacherName,
  });

  @override
  State<LiveSessionScreenSimple> createState() => _LiveSessionScreenSimpleState();
}

class _LiveSessionScreenSimpleState extends State<LiveSessionScreenSimple> {
  // Socket.IO
  IO.Socket? _socket;
  bool _isSocketConnected = false;

  // Chat
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();

  // Polls
  List<Poll> _polls = [];
  String? _currentPollId;

  // Content sharing
  String? _sharedContentUrl;
  String? _sharedContentType;

  // UI
  bool _showChat = false;
  bool _showPolls = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _joinSession();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    try {
      _socket = IO.io('http://192.168.29.104:5000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        setState(() {
          _isSocketConnected = true;
        });
      });

      _socket!.onDisconnect((_) {
        setState(() {
          _isSocketConnected = false;
        });
      });

      _socket!.on('chat_message', (data) {
        setState(() {
          _chatMessages.add(ChatMessage.fromJson(data));
        });
        _scrollToBottom();
      });

      _socket!.on('new_poll', (data) {
        setState(() {
          _polls.add(Poll.fromJson(data));
          _currentPollId = data['poll_id'];
        });
      });

      _socket!.on('content_shared', (data) {
        setState(() {
          _sharedContentUrl = data['url'];
          _sharedContentType = data['type'];
        });
      });

      _socket!.on('error', (data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinSession() async {
    if (_socket != null && _isSocketConnected) {
      _socket!.emit('join_session', {
        'session_id': widget.sessionId,
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _socket != null) {
      _socket!.emit('chat_message', {
        'session_id': widget.sessionId,
        'message': _messageController.text.trim(),
        'user_name': 'Student',
        'user_type': 'student',
      });
      _messageController.clear();
    }
  }

  void _submitPollResponse(String pollId, String response) {
    if (_socket != null) {
      _socket!.emit('submit_poll_response', {
        'poll_id': pollId,
        'response': response,
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lectureTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showChat ? Icons.chat : Icons.chat_outlined),
            onPressed: () {
              setState(() {
                _showChat = !_showChat;
              });
            },
          ),
          IconButton(
            icon: Icon(_showPolls ? Icons.poll : Icons.poll_outlined),
            onPressed: () {
              setState(() {
                _showPolls = !_showPolls;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _isSocketConnected ? Colors.green : Colors.orange,
            child: Text(
              _isSocketConnected ? 'Connected to Live Session' : 'Connecting...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Main content
                Expanded(
                  flex: _showChat || _showPolls ? 2 : 1,
                  child: Column(
                    children: [
                      // Teacher info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instructor: ${widget.teacherName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Session ID: ${widget.sessionId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Audio-only mode (WebRTC disabled for testing)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Shared content
                      if (_sharedContentUrl != null)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: _buildSharedContent(),
                          ),
                        ),
                      
                      // Current poll
                      if (_currentPollId != null)
                        Container(
                          margin: const EdgeInsets.all(8),
                          child: _buildCurrentPoll(),
                        ),
                    ],
                  ),
                ),
                
                // Chat and polls sidebar
                if (_showChat || _showPolls)
                  Container(
                    width: 300,
                    child: Column(
                      children: [
                        if (_showChat) Expanded(child: _buildChat()),
                        if (_showPolls) Expanded(child: _buildPolls()),
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

  Widget _buildSharedContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _sharedContentType == 'image' ? Icons.image : Icons.description,
                color: Colors.indigo,
              ),
              const SizedBox(width: 8),
              const Text(
                'Shared Content',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: _sharedContentType == 'image'
                ? Image.network(_sharedContentUrl!)
                : Text('Document: $_sharedContentUrl'),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPoll() {
    final poll = _polls.firstWhere(
      (p) => p.id == _currentPollId,
      orElse: () => Poll(id: '', question: '', options: [], hasVoted: false),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...poll.options.map((option) => 
              ElevatedButton(
                onPressed: poll.hasVoted ? null : () {
                  _submitPollResponse(poll.id, option);
                  setState(() {
                    poll.hasVoted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(option),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Live Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: message.isFromTeacher 
                        ? Colors.blue[50] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(message.message),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolls() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.poll, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Polls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                final poll = _polls[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...poll.options.map((option) => 
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $option'),
                        ),
                      ).toList(),
                      if (poll.hasVoted)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Voted',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Data models for chat and polls
class ChatMessage {
  final String userName;
  final String message;
  final bool isFromTeacher;
  final DateTime timestamp;

  ChatMessage({
    required this.userName,
    required this.message,
    required this.isFromTeacher,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userName: json['user_name'] ?? 'Unknown',
      message: json['message'] ?? '',
      isFromTeacher: json['user_type'] == 'teacher',
      timestamp: DateTime.now(),
    );
  }
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  bool hasVoted;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    this.hasVoted = false,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['poll_id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
    );
  }
}
