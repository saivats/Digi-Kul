import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:digikul_student_app/src/core/config/app_config.dart';
import 'package:digikul_student_app/src/core/constants/app_constants.dart';
import 'package:digikul_student_app/src/data/models/chat_message.dart';
import 'package:digikul_student_app/src/data/models/user.dart';

/// Socket service for real-time communication during live sessions
class SocketService {
  factory SocketService() => _instance;

  SocketService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  late IO.Socket _socket;
  late Logger _logger;
  
  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentSessionId;
  UserSession? _currentUser;
  
  // Stream controllers for real-time events
  final _connectionController = StreamController<bool>.broadcast();
  final _chatMessageController = StreamController<ChatMessage>.broadcast();
  final _userJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _userLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _sessionEndedController = StreamController<void>.broadcast();
  final _pollCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _materialSharedController = StreamController<Map<String, dynamic>>.broadcast();
  final _qualityReportController = StreamController<Map<String, dynamic>>.broadcast();
  
  // WebRTC signaling streams
  final _webrtcOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _webrtcAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController = StreamController<Map<String, dynamic>>.broadcast();

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentSessionId => _currentSessionId;
  
  // Stream getters
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ChatMessage> get chatMessageStream => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get userJoinedStream => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeftStream => _userLeftController.stream;
  Stream<void> get sessionEndedStream => _sessionEndedController.stream;
  Stream<Map<String, dynamic>> get pollCreatedStream => _pollCreatedController.stream;
  Stream<Map<String, dynamic>> get materialSharedStream => _materialSharedController.stream;
  Stream<Map<String, dynamic>> get qualityReportStream => _qualityReportController.stream;
  
  // WebRTC signaling streams
  Stream<Map<String, dynamic>> get webrtcOfferStream => _webrtcOfferController.stream;
  Stream<Map<String, dynamic>> get webrtcAnswerStream => _webrtcAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidateStream => _iceCandidateController.stream;

  /// Initialize socket connection
  void initialize(UserSession user) {
    _currentUser = user;
    
    if (_isConnected || _isConnecting) {
      _logger.w('Socket already connected or connecting');
      return;
    }

    _isConnecting = true;
    
    _socket = IO.io(
      EnvironmentConfig.socketUrl,
      IO.OptionBuilder()
          .setNamespace(AppConfig.socketNamespace)
          .setAutoConnect(AppConfig.autoConnect)
          .setReconnectionDelay(AppConfig.reconnectionDelay.inMilliseconds)
          .setMaxReconnectionAttempts(AppConfig.maxReconnectionAttempts)
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({
            'User-Agent': 'DigiKul-Student-App',
            'X-User-ID': user.userId,
            'X-User-Type': user.userType,
          })
          .build(),
    );

    _setupEventListeners();
    
    if (!AppConfig.autoConnect) {
      _socket.connect();
    }
  }

  void _setupEventListeners() {
    // Connection events
    _socket.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Socket connected successfully');
      }

      // Join user type room for broadcasts
      if (_currentUser != null) {
        _socket.emit('join_room', {
          'room': '${_currentUser!.userType}s', // 'students' or 'teachers'
          'user_id': _currentUser!.userId,
          'user_name': _currentUser!.userName,
        });
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(false);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.w('Socket disconnected');
      }
    });

    _socket.onConnectError((error) {
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(false);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.e('Socket connection error: $error');
      }
    });

    _socket.onError((error) {
      if (EnvironmentConfig.enableLogging) {
        _logger.e('Socket error: $error');
      }
    });

    // Chat events
    _socket.on(AppConstants.chatMessageEvent, (data) {
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);
        _chatMessageController.add(message);
      } catch (e) {
        _logger.e('Error parsing chat message: $e');
      }
    });

    // Session events
    _socket.on(AppConstants.userJoinedEvent, (data) {
      _userJoinedController.add(data as Map<String, dynamic>);
      
      // Add system message to chat
      final userName = data['user_name'] as String?;
      if (userName != null) {
        _chatMessageController.add(SystemMessage.userJoined(userName));
      }
    });

    _socket.on(AppConstants.userLeftEvent, (data) {
      _userLeftController.add(data as Map<String, dynamic>);
      
      // Add system message to chat
      final userName = data['user_name'] as String?;
      if (userName != null) {
        _chatMessageController.add(SystemMessage.userLeft(userName));
      }
    });

    _socket.on(AppConstants.sessionEndedEvent, (_) {
      _sessionEndedController.add(null);
      _chatMessageController.add(SystemMessage.sessionEnded());
    });

    // Content events
    _socket.on(AppConstants.newLectureEvent, (data) {
      if (EnvironmentConfig.enableLogging) {
        _logger.i('New lecture notification: ${data['title']}');
      }
    });

    _socket.on(AppConstants.newMaterialEvent, (data) {
      _materialSharedController.add(data as Map<String, dynamic>);
      
      final materialTitle = data['title'] as String?;
      if (materialTitle != null) {
        _chatMessageController.add(SystemMessage.materialShared(materialTitle));
      }
    });

    _socket.on('new_poll', (data) {
      _pollCreatedController.add(data as Map<String, dynamic>);
      
      final pollQuestion = data['question'] as String?;
      if (pollQuestion != null) {
        _chatMessageController.add(SystemMessage.pollCreated(pollQuestion));
      }
    });

    _socket.on(AppConstants.liveSessionStartedEvent, (data) {
      _chatMessageController.add(SystemMessage.sessionStarted());
    });

    // WebRTC signaling events
    _socket.on(AppConstants.webrtcOfferEvent, (data) {
      _webrtcOfferController.add(data as Map<String, dynamic>);
    });

    _socket.on(AppConstants.webrtcAnswerEvent, (data) {
      _webrtcAnswerController.add(data as Map<String, dynamic>);
    });

    _socket.on(AppConstants.iceCandidateEvent, (data) {
      _iceCandidateController.add(data as Map<String, dynamic>);
    });

    // Quality monitoring
    _socket.on(AppConstants.qualityReportEvent, (data) {
      _qualityReportController.add(data as Map<String, dynamic>);
    });
  }

  /// Join a live session
  Future<void> joinSession(String sessionId) async {
    if (!_isConnected) {
      throw Exception('Socket not connected');
    }

    if (_currentUser == null) {
      throw Exception('User session not available');
    }

    _currentSessionId = sessionId;

    _socket.emit(AppConstants.joinSessionEvent, {
      'session_id': sessionId,
      'user_id': _currentUser!.userId,
      'user_type': _currentUser!.userType,
      'user_name': _currentUser!.userName,
    });

    if (EnvironmentConfig.enableLogging) {
      _logger.i('Joined session: $sessionId');
    }
  }

  /// Leave current session
  Future<void> leaveSession() async {
    if (!_isConnected || _currentSessionId == null) {
      return;
    }

    _socket.emit(AppConstants.leaveSessionEvent, {
      'session_id': _currentSessionId,
      'user_id': _currentUser?.userId,
    });

    _currentSessionId = null;

    if (EnvironmentConfig.enableLogging) {
      _logger.i('Left session');
    }
  }

  /// Send chat message
  Future<void> sendChatMessage(String message, {String? sessionId}) async {
    if (!_isConnected) {
      throw Exception('Socket not connected');
    }

    final messageData = {
      'session_id': sessionId ?? _currentSessionId,
      'user_id': _currentUser?.userId,
      'user_name': _currentUser?.userName,
      'user_type': _currentUser?.userType,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket.emit(AppConstants.chatMessageEvent, messageData);

    if (EnvironmentConfig.enableLogging) {
      _logger.d('Sent chat message: $message');
    }
  }

  /// Send WebRTC offer
  Future<void> sendWebRTCOffer({
    required String sessionId,
    required String targetUserId,
    required Map<String, dynamic> offer,
  }) async {
    if (!_isConnected) {
      throw Exception('Socket not connected');
    }

    _socket.emit(AppConstants.webrtcOfferEvent, {
      'session_id': sessionId,
      'target_user_id': targetUserId,
      'from_user_id': _currentUser?.userId,
      'offer': offer,
    });
  }

  /// Send WebRTC answer
  Future<void> sendWebRTCAnswer({
    required String sessionId,
    required String targetUserId,
    required Map<String, dynamic> answer,
  }) async {
    if (!_isConnected) {
      throw Exception('Socket not connected');
    }

    _socket.emit(AppConstants.webrtcAnswerEvent, {
      'session_id': sessionId,
      'target_user_id': targetUserId,
      'from_user_id': _currentUser?.userId,
      'answer': answer,
    });
  }

  /// Send ICE candidate
  Future<void> sendICECandidate({
    required String sessionId,
    required String targetUserId,
    required Map<String, dynamic> candidate,
  }) async {
    if (!_isConnected) {
      throw Exception('Socket not connected');
    }

    _socket.emit(AppConstants.iceCandidateEvent, {
      'session_id': sessionId,
      'target_user_id': targetUserId,
      'from_user_id': _currentUser?.userId,
      'candidate': candidate,
    });
  }

  /// Send quality report
  Future<void> sendQualityReport(Map<String, dynamic> qualityData) async {
    if (!_isConnected) {
      return;
    }

    _socket.emit(AppConstants.qualityReportEvent, {
      'session_id': _currentSessionId,
      'user_id': _currentUser?.userId,
      'quality_data': qualityData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    if (_isConnected) {
      return;
    }

    if (_isConnecting) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    _isConnecting = true;
    _socket.connect();
  }

  /// Disconnect socket
  Future<void> disconnect() async {
    if (_currentSessionId != null) {
      await leaveSession();
    }

    _isConnected = false;
    _isConnecting = false;
    _currentSessionId = null;
    
    _socket.disconnect();
    _socket.dispose();

    if (EnvironmentConfig.enableLogging) {
      _logger.i('Socket disconnected and disposed');
    }
  }

  /// Check connection status
  bool checkConnection() {
    return _socket.connected;
  }

  /// Get connection latency (ping)
  Future<int?> getLatency() async {
    if (!_isConnected) {
      return null;
    }

    final completer = Completer<int>();
    final startTime = DateTime.now().millisecondsSinceEpoch;

    _socket.emitWithAck('ping', null, ack: (data) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      completer.complete(latency);
    },);

    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    
    // Close all stream controllers
    _connectionController.close();
    _chatMessageController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _sessionEndedController.close();
    _pollCreatedController.close();
    _materialSharedController.close();
    _qualityReportController.close();
    _webrtcOfferController.close();
    _webrtcAnswerController.close();
    _iceCandidateController.close();
  }
}
