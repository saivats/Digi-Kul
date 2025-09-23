import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/chat_message.dart';
import '../models/poll.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _currentSessionId;
  String? _serverUrl;

  // Stream controllers for different events
  final StreamController<ConnectionStatus> _connectionStatusController = 
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _sessionInfoController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // WebRTC signaling streams
  final StreamController<Map<String, dynamic>> _webrtcOfferController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _webrtcAnswerController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _iceCandidateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Chat and interaction streams
  final StreamController<SocketChatMessage> _chatMessageController = 
      StreamController<SocketChatMessage>.broadcast();
  final StreamController<Poll> _newPollController = 
      StreamController<Poll>.broadcast();
  final StreamController<Map<String, dynamic>> _pollVoteController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _contentSharedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Error and notification streams
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public getters for streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get sessionInfo => _sessionInfoController.stream;
  Stream<Map<String, dynamic>> get userJoined => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeft => _userLeftController.stream;
  Stream<Map<String, dynamic>> get webrtcOffer => _webrtcOfferController.stream;
  Stream<Map<String, dynamic>> get webrtcAnswer => _webrtcAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidate => _iceCandidateController.stream;
  Stream<SocketChatMessage> get chatMessage => _chatMessageController.stream;
  Stream<Poll> get newPoll => _newPollController.stream;
  Stream<Map<String, dynamic>> get pollVote => _pollVoteController.stream;
  Stream<Map<String, dynamic>> get contentShared => _contentSharedController.stream;
  Stream<String> get error => _errorController.stream;
  Stream<Map<String, dynamic>> get notification => _notificationController.stream;

  // Public getters for state
  ConnectionStatus get status => _connectionStatus;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  String? get currentSessionId => _currentSessionId;

  Future<void> connect(String serverUrl) async {
    if (_connectionStatus == ConnectionStatus.connecting || 
        _connectionStatus == ConnectionStatus.connected) {
      return;
    }

    _serverUrl = serverUrl;
    _connectionStatus = ConnectionStatus.connecting;
    _connectionStatusController.add(_connectionStatus);

    try {
      _socket = io.io(serverUrl, io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build());

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      _connectionStatus = ConnectionStatus.error;
      _connectionStatusController.add(_connectionStatus);
      _errorController.add('Failed to connect to server: $e');
      debugPrint('Socket connection error: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _connectionStatus = ConnectionStatus.connected;
      _connectionStatusController.add(_connectionStatus);
      debugPrint('Socket.IO connected to $_serverUrl');
    });

    _socket!.onDisconnect((_) {
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionStatusController.add(_connectionStatus);
      debugPrint('Socket.IO disconnected');
    });

    _socket!.onConnectError((error) {
      _connectionStatus = ConnectionStatus.error;
      _connectionStatusController.add(_connectionStatus);
      _errorController.add('Connection error: $error');
      debugPrint('Socket.IO connection error: $error');
    });

    _socket!.onReconnect((attempt) {
      debugPrint('Socket.IO reconnected after $attempt attempts');
    });

    _socket!.onReconnectError((error) {
      debugPrint('Socket.IO reconnection error: $error');
    });

    // Session management events
    _socket!.on('session_info', (data) {
      try {
        final sessionData = Map<String, dynamic>.from(data);
        _sessionInfoController.add(sessionData);
      } catch (e) {
        debugPrint('Error parsing session_info: $e');
      }
    });

    _socket!.on('user_joined', (data) {
      try {
        final userData = Map<String, dynamic>.from(data);
        _userJoinedController.add(userData);
      } catch (e) {
        debugPrint('Error parsing user_joined: $e');
      }
    });

    _socket!.on('user_left', (data) {
      try {
        final userData = Map<String, dynamic>.from(data);
        _userLeftController.add(userData);
      } catch (e) {
        debugPrint('Error parsing user_left: $e');
      }
    });

    // WebRTC signaling events
    _socket!.on('webrtc_offer', (data) {
      try {
        final offerData = Map<String, dynamic>.from(data);
        _webrtcOfferController.add(offerData);
      } catch (e) {
        debugPrint('Error parsing webrtc_offer: $e');
      }
    });

    _socket!.on('webrtc_answer', (data) {
      try {
        final answerData = Map<String, dynamic>.from(data);
        _webrtcAnswerController.add(answerData);
      } catch (e) {
        debugPrint('Error parsing webrtc_answer: $e');
      }
    });

    _socket!.on('ice_candidate', (data) {
      try {
        final candidateData = Map<String, dynamic>.from(data);
        _iceCandidateController.add(candidateData);
      } catch (e) {
        debugPrint('Error parsing ice_candidate: $e');
      }
    });

    // Chat events
    _socket!.on('chat_message', (data) {
      try {
        final messageData = Map<String, dynamic>.from(data);
        final chatMessage = SocketChatMessage.fromJson(messageData);
        _chatMessageController.add(chatMessage);
        debugPrint('Received chat message: ${chatMessage.message}');
      } catch (e) {
        debugPrint('Error parsing chat_message: $e');
      }
    });

    // Poll events
    _socket!.on('new_poll', (data) {
      try {
        final pollData = Map<String, dynamic>.from(data);
        final poll = Poll.fromJson(pollData);
        _newPollController.add(poll);
        debugPrint('Received new poll: ${poll.question}');
      } catch (e) {
        debugPrint('Error parsing new_poll: $e');
      }
    });

    _socket!.on('poll_created', (data) {
      try {
        final pollData = Map<String, dynamic>.from(data);
        final poll = Poll.fromJson(pollData);
        _newPollController.add(poll);
      } catch (e) {
        debugPrint('Error parsing poll_created: $e');
      }
    });

    _socket!.on('poll_vote', (data) {
      try {
        final voteData = Map<String, dynamic>.from(data);
        _pollVoteController.add(voteData);
      } catch (e) {
        debugPrint('Error parsing poll_vote: $e');
      }
    });

    // Content sharing events
    _socket!.on('content_shared', (data) {
      try {
        final contentData = Map<String, dynamic>.from(data);
        _contentSharedController.add(contentData);
      } catch (e) {
        debugPrint('Error parsing content_shared: $e');
      }
    });

    // Lecture/session notifications
    _socket!.on('live_session_started', (data) {
      try {
        final sessionData = Map<String, dynamic>.from(data);
        _notificationController.add({
          'type': 'live_session_started',
          'data': sessionData,
        });
      } catch (e) {
        debugPrint('Error parsing live_session_started: $e');
      }
    });

    _socket!.on('new_lecture', (data) {
      try {
        final lectureData = Map<String, dynamic>.from(data);
        _notificationController.add({
          'type': 'new_lecture',
          'data': lectureData,
        });
      } catch (e) {
        debugPrint('Error parsing new_lecture: $e');
      }
    });

    _socket!.on('new_material', (data) {
      try {
        final materialData = Map<String, dynamic>.from(data);
        _notificationController.add({
          'type': 'new_material',
          'data': materialData,
        });
      } catch (e) {
        debugPrint('Error parsing new_material: $e');
      }
    });

    // Error events
    _socket!.on('error', (data) {
      final errorMessage = data is Map 
          ? (data['message'] ?? 'Unknown error') 
          : data.toString();
      _errorController.add(errorMessage);
    });

    // Connected confirmation
    _socket!.on('connected', (data) {
      debugPrint('Socket.IO server confirmed connection: $data');
    });

    // Session ended
    _socket!.on('session_ended', (data) {
      _currentSessionId = null;
      _notificationController.add({
        'type': 'session_ended',
        'data': data,
      });
    });
  }

  // Session management methods
  Future<void> joinSession(String sessionId) async {
    if (_socket == null || !isConnected) {
      throw Exception('Socket not connected');
    }

    _currentSessionId = sessionId;
    _socket!.emit('join_session', {'session_id': sessionId});
    debugPrint('Joining session: $sessionId');
  }

  Future<void> leaveSession() async {
    if (_socket == null || _currentSessionId == null) return;

    _socket!.emit('leave_session', {
      'session_id': _currentSessionId,
    });
    
    _currentSessionId = null;
    debugPrint('Left session');
  }

  // WebRTC signaling methods
  void sendWebRTCOffer(String targetUserId, Map<String, dynamic> offer) {
    if (_socket == null || !isConnected || _currentSessionId == null) {
      debugPrint('Cannot send WebRTC offer: not connected or no session');
      return;
    }

    _socket!.emit('webrtc_offer', {
      'session_id': _currentSessionId,
      'target_user_id': targetUserId,
      'from_user_id': 'student', // This should be dynamic
      'offer': offer,
    });
  }

  void sendWebRTCAnswer(String targetUserId, Map<String, dynamic> answer) {
    if (_socket == null || !isConnected || _currentSessionId == null) {
      debugPrint('Cannot send WebRTC answer: not connected or no session');
      return;
    }

    _socket!.emit('webrtc_answer', {
      'session_id': _currentSessionId,
      'target_user_id': targetUserId,
      'from_user_id': 'student', // This should be dynamic
      'answer': answer,
    });
  }

  void sendICECandidate(String targetUserId, Map<String, dynamic> candidate) {
    if (_socket == null || !isConnected || _currentSessionId == null) {
      debugPrint('Cannot send ICE candidate: not connected or no session');
      return;
    }

    _socket!.emit('ice_candidate', {
      'session_id': _currentSessionId,
      'target_user_id': targetUserId,
      'from_user_id': 'student', // This should be dynamic
      'candidate': candidate,
    });
  }

  // Chat methods
  void sendChatMessage(String message, {String userName = 'Student'}) {
    if (_socket == null || !isConnected || _currentSessionId == null) {
      debugPrint('Cannot send chat message: not connected or no session');
      return;
    }

    final chatData = {
      'session_id': _currentSessionId,
      'message': message,
      'user_name': userName,
      'user_type': 'student',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    debugPrint('Sending chat message: $message');
    _socket!.emit('chat_message', chatData);
  }

  // Poll methods
  void submitPollResponse(String pollId, String response) {
    if (_socket == null || !isConnected) {
      debugPrint('Cannot submit poll response: not connected');
      return;
    }

    _socket!.emit('submit_poll_response', {
      'poll_id': pollId,
      'response': response,
    });
  }

  void voteOnPoll(String pollId, String option) {
    if (_socket == null || !isConnected) {
      debugPrint('Cannot vote on poll: not connected');
      return;
    }

    _socket!.emit('vote', {
      'poll_id': pollId,
      'option': option,
    });
  }

  // Quality reporting (for adaptive streaming)
  void reportQuality(Map<String, dynamic> qualityData) {
    if (_socket == null || !isConnected) return;

    _socket!.emit('quality_report', qualityData);
  }

  // Generic emit method for custom events
  void emit(String event, dynamic data) {
    if (_socket == null || !isConnected) {
      debugPrint('Cannot emit $event: not connected');
      return;
    }
    
    _socket!.emit(event, data);
  }

  // Reconnection methods
  void reconnect() {
    if (_socket != null) {
      _socket!.connect();
    } else if (_serverUrl != null) {
      connect(_serverUrl!);
    }
  }

  void forceReconnect() {
    disconnect();
    if (_serverUrl != null) {
      Timer(const Duration(seconds: 1), () {
        connect(_serverUrl!);
      });
    }
  }

  void disconnect() {
    _currentSessionId = null;
    _connectionStatus = ConnectionStatus.disconnected;
    _connectionStatusController.add(_connectionStatus);
    
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    debugPrint('Socket disconnected and disposed');
  }

  void dispose() {
    disconnect();
    
    // Close all stream controllers
    _connectionStatusController.close();
    _sessionInfoController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _webrtcOfferController.close();
    _webrtcAnswerController.close();
    _iceCandidateController.close();
    _chatMessageController.close();
    _newPollController.close();
    _pollVoteController.close();
    _contentSharedController.close();
    _errorController.close();
    _notificationController.close();
    
    debugPrint('SocketService disposed');
  }
}
