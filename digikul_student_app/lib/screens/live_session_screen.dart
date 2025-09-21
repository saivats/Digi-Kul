import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import 'dart:async';

class LiveSessionScreen extends StatefulWidget {
  final String sessionId;
  final String lectureId;
  final String lectureTitle;
  final String teacherName;

  const LiveSessionScreen({
    super.key,
    required this.sessionId,
    required this.lectureId,
    required this.lectureTitle,
    required this.teacherName,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  // Services
  final SocketService _socketService = SocketService();
  final AudioService _audioService = AudioService();

  // Chat
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();

  // Polls
  final List<Poll> _polls = [];
  String? _currentPollId;

  // Content sharing
  String? _sharedContentUrl;
  String? _sharedContentType;

  // UI state
  bool _showChat = false;
  bool _showPolls = false;
  bool _isSocketConnected = false;
  bool _isAudioConnected = false;
  bool _isMuted = false;
  bool _isInitializing = true;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _webrtcOfferSubscription;
  StreamSubscription? _webrtcAnswerSubscription;
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _pollSubscription;
  StreamSubscription? _contentSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _webrtcConnectionSubscription;
  StreamSubscription? _sessionInfoSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _webrtcIceCandidateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Initialize Audio first
      final audioInitialized = await _audioService.initialize();
      if (!audioInitialized) {
        throw Exception('Failed to initialize audio system');
      }

      // Connect to Socket.IO
      await _socketService.connect('http://192.168.29.104:5000');
      
      // Set up event listeners
      _setupEventListeners();
      
      // Join the session
      await _socketService.joinSession(widget.sessionId);
      await _audioService.joinSession(widget.sessionId);
      
      // Load initial polls for this lecture
      await _loadLecturePolls();
      
      setState(() {
        _isInitializing = false;
        _isMuted = _audioService.isMuted;
      });
      
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
      _showError('Failed to initialize live session: $e');
    }
  }

  void _setupEventListeners() {
    // Socket connection state
    _connectionSubscription = _socketService.connectionState.listen((connected) {
      setState(() {
        _isSocketConnected = connected;
      });
    });

    // Audio connection state
    _webrtcConnectionSubscription = _audioService.connectionState.listen((connected) {
      setState(() {
        _isAudioConnected = connected;
      });
    });

    // Session info and participants
    _sessionInfoSubscription = _socketService.sessionInfo.listen((data) {
      // Handle session participants and initiate WebRTC connections
      final participants = data['participants'] as List?;
      if (participants != null) {
        for (final participant in participants) {
          final participantId = participant['user_id'];
          final participantType = participant['user_type'];
          if (participantType == 'teacher') {
            // Initiate audio connection with teacher
            _initiateAudioConnection(participantId);
          }
        }
      }
    });

    _userJoinedSubscription = _socketService.userJoined.listen((data) {
      final userId = data['user_id'];
      final userType = data['user_type'];
      if (userType == 'teacher') {
        // Initiate audio connection with teacher
        _initiateAudioConnection(userId);
      }
    });

    // Audio signaling events (simplified)
    _webrtcOfferSubscription = _socketService.webrtcOffer.listen((data) async {
      try {
        // Handle audio offer from teacher
        _socketService.sendAudioAnswer(data['from_user_id']);
        setState(() {
          _isAudioConnected = true;
        });
      } catch (e) {
        _showError('Failed to handle audio offer: $e');
      }
    });

    // Chat messages
    _chatSubscription = _socketService.chatMessage.listen((data) {
      setState(() {
        _chatMessages.add(ChatMessage.fromJson(data));
      });
      _scrollToBottom();
    });

    // Polls
    _pollSubscription = _socketService.newPoll.listen((data) {
      setState(() {
        _polls.add(Poll(
          id: data['poll_id'] ?? '',
          question: data['question'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          hasVoted: false,
        ));
        _currentPollId = data['poll_id'];
      });
    });

    // Content sharing
    _contentSubscription = _socketService.contentShared.listen((data) {
      setState(() {
        _sharedContentUrl = data['url'];
        _sharedContentType = data['type'];
      });
    });

    // Error handling
    _errorSubscription = _socketService.errorStream.listen((error) {
      _showError(error);
    });
  }

  Future<void> _initiateAudioConnection(String targetUserId) async {
    try {
      _socketService.sendAudioOffer(targetUserId);
    } catch (e) {
      _showError('Failed to initiate audio connection: $e');
    }
  }

  Future<void> _loadLecturePolls() async {
    try {
      final polls = await ApiService.getLecturePolls(widget.lectureId);
      setState(() {
        _polls.clear();
        for (final poll in polls) {
          _polls.add(Poll(
            id: poll.id,
            question: poll.question,
            options: poll.options,
            hasVoted: false,
          ));
        }
      });
    } catch (e) {
      print('Failed to load lecture polls: $e');
      // Don't show error for polls as it's not critical
    }
  }

  Future<void> _cleanup() async {
    // Cancel all subscriptions
    await _connectionSubscription?.cancel();
    await _webrtcOfferSubscription?.cancel();
    await _webrtcAnswerSubscription?.cancel();
    await _iceCandidateSubscription?.cancel();
    await _chatSubscription?.cancel();
    await _pollSubscription?.cancel();
    await _contentSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _webrtcConnectionSubscription?.cancel();
    await _sessionInfoSubscription?.cancel();
    await _userJoinedSubscription?.cancel();
    await _webrtcIceCandidateSubscription?.cancel();

    // Cleanup services
    await _audioService.leaveSession();
    await _socketService.leaveSession();
    _socketService.disconnect();

    // Dispose controllers
    _messageController.dispose();
    _chatScrollController.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _socketService.sendChatMessage(_messageController.text.trim());
      _messageController.clear();
    }
  }

  Future<void> _submitPollResponse(String pollId, String response) async {
    try {
      await ApiService.voteOnPoll(pollId, response);
      _socketService.submitPollResponse(pollId, response);
      
      // Update local poll state
      setState(() {
        final pollIndex = _polls.indexWhere((p) => p.id == pollId);
        if (pollIndex != -1) {
          // Mark poll as voted (you might need to add this field to Poll model)
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to submit vote: $e');
    }
  }

  Future<void> _toggleMute() async {
    await _audioService.toggleMute();
    setState(() {
      _isMuted = _audioService.isMuted;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
          if (!_isInitializing) ...[
            IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute' : 'Mute',
              color: _isMuted ? Colors.red : Colors.white,
            ),
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
        ],
      ),
      body: _isInitializing 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing live session...'),
                SizedBox(height: 8),
                Text('Setting up audio and connecting to server'),
              ],
            ),
          )
        : _errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to join session', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeServices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _isAudioConnected ? Colors.green : (_isSocketConnected ? Colors.blue : Colors.orange),
            child: Text(
              _isAudioConnected 
                ? 'Audio Connected - You can hear the teacher' 
                : _isSocketConnected 
                  ? 'Connected - Setting up audio...'
                  : 'Connecting...',
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
                                color: _isAudioConnected ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAudioConnected ? Icons.volume_up : Icons.volume_off,
                                    size: 16,
                                    color: _isAudioConnected ? Colors.green[700] : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isAudioConnected 
                                      ? 'Audio Active - Real-time Class'
                                      : 'Setting up audio connection...',
                                    style: TextStyle(
                                      color: _isAudioConnected ? Colors.green[700] : Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
