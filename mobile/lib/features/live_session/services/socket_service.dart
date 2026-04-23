import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/session/session_state.dart';

typedef EventCallback = void Function(Map<String, dynamic> data);

class SocketService {
  SocketService({
    required String sessionId,
    required String authToken,
  })  : _sessionId = sessionId,
        _authToken = authToken;

  final String _sessionId;
  final String _authToken;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  io.Socket? _socket;

  final _participantJoined = StreamController<Participant>.broadcast();
  final _participantsSnapshot = StreamController<List<Participant>>.broadcast();
  final _participantLeft = StreamController<String>.broadcast();
  final _chatMessage = StreamController<ChatMessage>.broadcast();
  final _webRtcOffer = StreamController<Map<String, dynamic>>.broadcast();
  final _webRtcAnswer = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidate = StreamController<Map<String, dynamic>>.broadcast();
  final _pollStarted = StreamController<ActivePoll>.broadcast();
  final _pollEnded = StreamController<String>.broadcast();
  final _sessionEnded = StreamController<void>.broadcast();
  final _modeChanged = StreamController<SessionMode>.broadcast();
  final _audioLevel = StreamController<Map<String, double>>.broadcast();
  final _connectionStatus =
      StreamController<SessionConnectionStatus>.broadcast();

  Stream<Participant> get onParticipantJoined => _participantJoined.stream;
  Stream<List<Participant>> get onParticipantsSnapshot =>
      _participantsSnapshot.stream;
  Stream<String> get onParticipantLeft => _participantLeft.stream;
  Stream<ChatMessage> get onChatMessage => _chatMessage.stream;
  Stream<Map<String, dynamic>> get onWebRtcOffer => _webRtcOffer.stream;
  Stream<Map<String, dynamic>> get onWebRtcAnswer => _webRtcAnswer.stream;
  Stream<Map<String, dynamic>> get onIceCandidate => _iceCandidate.stream;
  Stream<ActivePoll> get onPollStarted => _pollStarted.stream;
  Stream<String> get onPollEnded => _pollEnded.stream;
  Stream<void> get onSessionEnded => _sessionEnded.stream;
  Stream<SessionMode> get onModeChanged => _modeChanged.stream;
  Stream<Map<String, double>> get onAudioLevel => _audioLevel.stream;
  Stream<SessionConnectionStatus> get onConnectionStatus =>
      _connectionStatus.stream;

  Future<void> connect() async {
    final sessionCookie = await SecureStorageService.getSessionCookie();
    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({
            if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
            if (sessionCookie != null && sessionCookie.isNotEmpty)
              'Cookie': sessionCookie,
          })
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      _logger.i('Socket connected');
      _connectionStatus.add(SessionConnectionStatus.connected);
      _socket!.emit('join_session', {'session_id': _sessionId});
    });

    _socket!.onDisconnect((_) {
      _logger.w('Socket disconnected');
      _connectionStatus.add(SessionConnectionStatus.disconnected);
    });

    _socket!.onReconnecting((_) {
      _connectionStatus.add(SessionConnectionStatus.reconnecting);
    });

    _socket!.onReconnect((_) {
      _connectionStatus.add(SessionConnectionStatus.connected);
      _socket!.emit('join_session', {'session_id': _sessionId});
    });

    _socket!.onError((error) {
      _logger.e('Socket error: $error');
      _connectionStatus.add(SessionConnectionStatus.error);
    });

    _socket!.on('user_joined', (data) {
      if (data is Map) {
        _participantJoined.add(_participantFromSocket(data));
      }
    });

    _socket!.on('session_participants', (data) {
      if (data is List) {
        _participantsSnapshot.add(
          data.whereType<Map>().map(_participantFromSocket).toList(),
        );
      }
    });

    _socket!.on('user_left', (data) {
      if (data is Map) {
        _participantLeft.add(data['user_id'] as String? ?? '');
      }
    });

    _socket!.on('chat_message', (data) {
      if (data is Map) {
        _chatMessage.add(_chatMessageFromSocket(data));
      }
    });

    _socket!.on('poll_started', (data) {
      if (data is Map<String, dynamic>) {
        _pollStarted.add(ActivePoll.fromJson(data));
      }
    });

    _socket!.on('poll_ended', (data) {
      if (data is Map<String, dynamic>) {
        _pollEnded.add(data['poll_id'] as String? ?? '');
      }
    });

    _socket!.on('session_ended', (_) {
      _sessionEnded.add(null);
    });

    _socket!.on('mode_changed', (data) {
      if (data is Map<String, dynamic>) {
        final modeStr = data['mode'] as String? ?? 'audio';
        final mode = SessionMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => SessionMode.audio,
        );
        _modeChanged.add(mode);
      }
    });

    _socket!.on('audio_levels', (data) {
      if (data is Map<String, dynamic>) {
        _audioLevel.add(data.map((k, v) => MapEntry(k, (v as num).toDouble())));
      }
    });

    _socket!.on('webrtc_offer', (data) {
      if (data is Map) _webRtcOffer.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('webrtc_answer', (data) {
      if (data is Map) _webRtcAnswer.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('ice_candidate', (data) {
      if (data is Map) _iceCandidate.add(Map<String, dynamic>.from(data));
    });
  }

  void sendChatMessage(String content) {
    _socket?.emit('chat_message', {
      'session_id': _sessionId,
      'message': content,
    });
  }

  void votePoll(String pollId, String option) {
    _socket?.emit('vote_poll', {
      'session_id': _sessionId,
      'poll_id': pollId,
      'option': option,
    });
  }

  void sendOffer(String targetId, Map<String, dynamic> sdp) {
    _socket?.emit('webrtc_offer', {
      'session_id': _sessionId,
      'target_user_id': targetId,
      'offer': sdp,
    });
  }

  void sendAnswer(String targetId, Map<String, dynamic> sdp) {
    _socket?.emit('webrtc_answer', {
      'session_id': _sessionId,
      'target_user_id': targetId,
      'answer': sdp,
    });
  }

  void sendIceCandidate(String targetId, Map<String, dynamic> candidate) {
    _socket?.emit('ice_candidate', {
      'session_id': _sessionId,
      'target_user_id': targetId,
      'candidate': candidate,
    });
  }

  void leaveSession() {
    _socket?.emit('leave_session', {'session_id': _sessionId});
  }

  void dispose() {
    leaveSession();
    _socket?.disconnect();
    _socket?.dispose();
    _participantJoined.close();
    _participantsSnapshot.close();
    _participantLeft.close();
    _chatMessage.close();
    _webRtcOffer.close();
    _webRtcAnswer.close();
    _iceCandidate.close();
    _pollStarted.close();
    _pollEnded.close();
    _sessionEnded.close();
    _modeChanged.close();
    _audioLevel.close();
    _connectionStatus.close();
  }

  Participant _participantFromSocket(Map<dynamic, dynamic> data) {
    final userId = data['user_id'] as String? ?? data['id'] as String? ?? '';
    final role =
        data['user_type'] as String? ?? data['role'] as String? ?? 'student';
    return Participant(
      id: userId,
      name: data['user_name'] as String? ?? data['name'] as String? ?? 'User',
      role: role,
      isMuted: data['is_muted'] as bool? ?? false,
    );
  }

  ChatMessage _chatMessageFromSocket(Map<dynamic, dynamic> data) {
    return ChatMessage(
      id: data['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      senderId:
          data['user_id'] as String? ?? data['sender_id'] as String? ?? '',
      senderName: data['user_name'] as String? ??
          data['sender_name'] as String? ??
          'User',
      content: data['message'] as String? ?? data['content'] as String? ?? '',
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.now(),
      senderRole:
          data['user_type'] as String? ?? data['role'] as String? ?? 'student',
    );
  }
}
