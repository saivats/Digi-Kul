import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  factory SocketService() => _instance;
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentSessionId;
  
  // Event streams for all real-time features
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _sessionInfoController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _webrtcOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _webrtcAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _iceCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _newPollController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _pollCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _pollVoteController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _contentSharedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters for all streams
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get sessionInfo => _sessionInfoController.stream;
  Stream<Map<String, dynamic>> get userJoined => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeft => _userLeftController.stream;
  Stream<Map<String, dynamic>> get webrtcOffer => _webrtcOfferController.stream;
  Stream<Map<String, dynamic>> get webrtcAnswer => _webrtcAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidate => _iceCandidateController.stream;
  Stream<Map<String, dynamic>> get chatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get newPoll => _newPollController.stream;
  Stream<Map<String, dynamic>> get pollCreated => _pollCreatedController.stream;
  Stream<Map<String, dynamic>> get pollVote => _pollVoteController.stream;
  Stream<Map<String, dynamic>> get contentShared => _contentSharedController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String serverUrl) async {
    if (_isConnected) return;

    try {
      _socket = io.io(serverUrl, io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),);

      _setupEventListeners();
      
      _socket!.connect();
    } catch (e) {
      _errorController.add('Failed to connect to server: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionStateController.add(true);
      print('Socket.IO connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionStateController.add(false);
      print('Socket.IO disconnected');
    });

    _socket!.onConnectError((error) {
      _errorController.add('Connection error: $error');
      print('Socket.IO connection error: $error');
    });

    // Session management events
    _socket!.on('session_info', (data) {
      _sessionInfoController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_joined', (data) {
      _userJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_left', (data) {
      _userLeftController.add(Map<String, dynamic>.from(data));
    });

    // WebRTC signaling events
    _socket!.on('webrtc_offer', (data) {
      _webrtcOfferController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('webrtc_answer', (data) {
      _webrtcAnswerController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('ice_candidate', (data) {
      _iceCandidateController.add(Map<String, dynamic>.from(data));
    });

    // Chat events
    _socket!.on('chat_message', (data) {
      print('SocketService received chat_message: $data'); // Debug print
      _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    // Poll events
    _socket!.on('new_poll', (data) {
      _newPollController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('poll_created', (data) {
      _pollCreatedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('poll_vote', (data) {
      _pollVoteController.add(Map<String, dynamic>.from(data));
    });

    // Content sharing events
    _socket!.on('content_shared', (data) {
      _contentSharedController.add(Map<String, dynamic>.from(data));
    });

    // Error events
    _socket!.on('error', (data) {
      final errorMessage = data is Map ? (data['message'] ?? 'Unknown error') : data.toString();
      _errorController.add(errorMessage);
    });

    // Connected confirmation
    _socket!.on('connected', (data) {
      print('Socket.IO server confirmed connection: $data');
    });
  }

  // Session management methods
  Future<void> joinSession(String sessionId) async {
    if (_socket == null || !_isConnected) {
      throw Exception('Socket not connected');
    }

    _currentSessionId = sessionId;
    _socket!.emit('join_session', {'session_id': sessionId});
  }

  Future<void> leaveSession() async {
    if (_socket == null || _currentSessionId == null) return;

    _socket!.emit('leave_session', {
      'session_id': _currentSessionId,
    });
    
    _currentSessionId = null;
  }

  // Audio signaling methods (simplified for compatibility)
  void sendAudioOffer(String targetUserId) {
    if (_socket == null || !_isConnected || _currentSessionId == null) return;

    _socket!.emit('webrtc_offer', {
      'session_id': _currentSessionId,
      'target_user_id': targetUserId,
      'from_user_id': 'student',
    });
  }

  void sendAudioAnswer(String targetUserId) {
    if (_socket == null || !_isConnected || _currentSessionId == null) return;

    _socket!.emit('webrtc_answer', {
      'session_id': _currentSessionId,
      'target_user_id': targetUserId,
      'from_user_id': 'student',
    });
  }

  // Chat methods
  void sendChatMessage(String message) {
    if (_socket == null || !_isConnected || _currentSessionId == null) {
      print('Cannot send chat message: socket not connected or session ID null');
      return;
    }

    final chatData = {
      'session_id': _currentSessionId,
      'message': message,
      'user_name': 'Student',
      'user_type': 'student',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('Sending chat message to server: $chatData'); // Debug print
    _socket!.emit('chat_message', chatData);
  }

  // Poll methods
  void submitPollResponse(String pollId, String response) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit('submit_poll_response', {
      'poll_id': pollId,
      'response': response,
    });
  }

  void voteOnPoll(String pollId, String response) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit('vote', {
      'poll_id': pollId,
      'option': response,
    });
  }

  // Generic emit method for custom events
  void emit(String event, dynamic data) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit(event, data);
  }

  void disconnect() {
    _currentSessionId = null;
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _sessionInfoController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _webrtcOfferController.close();
    _webrtcAnswerController.close();
    _iceCandidateController.close();
    _chatMessageController.close();
    _newPollController.close();
    _pollCreatedController.close();
    _pollVoteController.close();
    _contentSharedController.close();
    _errorController.close();
  }
}
