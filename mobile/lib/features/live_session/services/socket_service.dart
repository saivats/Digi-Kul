import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/api_constants.dart';
import '../../../models/session/session_state.dart';

typedef EventCallback = void Function(Map<String, dynamic> data);

/// Socket.IO client for a live session.
///
/// Follows the backend contract in backend/app/socket_manager.py — the same
/// handshake the web client uses:
///
///   connect
///     -> emit `authenticate` {token}
///     <- `authenticated`            (or `auth_error`)
///     -> emit `join_session` {token, session_id}
///     <- `session_joined` {participants: [...], whiteboard_strokes, is_recording}
///   ongoing:
///     <- participant_joined / participant_left
///     <- chat_message, hand_raised, poll_created, poll_response
///     <- recording_started / recording_stopped, muted, session_ended
///     <- webrtc_offer {from_user_id, sdp} / webrtc_ice_candidate {from_user_id, candidate}
///     <- session_error {action, error}, rate_limited {event}
///
/// The JWT travels INSIDE event payloads (`token`), not as an HTTP header —
/// the server reads `data["token"]`. Every reconnect re-runs the whole
/// handshake automatically.
class SocketService {
  SocketService({
    required String sessionId,
    required String authToken,
    required String studentId,
    required String studentName,
  })  : _sessionId = sessionId,
        _authToken = authToken,
        _studentId = studentId,
        _studentName = studentName;

  final String _sessionId;
  final String _authToken;
  final String _studentId;
  final String _studentName;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  io.Socket? _socket;
  bool _everConnected = false;

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
  final _recordingChanged = StreamController<bool>.broadcast();
  final _muted = StreamController<String>.broadcast();
  final _handRaised = StreamController<Participant>.broadcast();
  final _sessionError = StreamController<String>.broadcast();
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
  Stream<bool> get onRecordingChanged => _recordingChanged.stream;
  Stream<String> get onMuted => _muted.stream;
  Stream<Participant> get onHandRaised => _handRaised.stream;
  Stream<String> get onSessionError => _sessionError.stream;
  Stream<SessionConnectionStatus> get onConnectionStatus =>
      _connectionStatus.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setPath(ApiConstants.socketPath)
          .setTransports(['websocket', 'polling'])
          // Also sent on the handshake so the server can pre-seed identity;
          // the explicit `authenticate` event below is what the contract needs.
          .setAuth({'token': _authToken})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(1 << 30) // effectively unlimited
          .build(),
    );

    final socket = _socket!;

    // ---- handshake -----------------------------------------------------
    socket.onConnect((_) {
      _logger.i(_everConnected ? 'Socket reconnected' : 'Socket connected');
      _everConnected = true;
      _connectionStatus.add(SessionConnectionStatus.connecting);
      socket.emit('authenticate', {'token': _authToken});
    });

    socket.on('authenticated', (_) {
      socket.emit('join_session', {
        'token': _authToken,
        'session_id': _sessionId,
      });
    });

    socket.on('auth_error', (data) {
      _logger.e('Socket auth error: $data');
      _sessionError.add('Authentication failed — please sign in again.');
      _connectionStatus.add(SessionConnectionStatus.error);
      socket.disconnect();
    });

    socket.on('session_joined', (data) {
      if (data is! Map) return;
      final list = (data['participants'] as List? ?? const [])
          .whereType<Map>()
          .map(_participantFromSocket)
          .toList();
      _participantsSnapshot.add(list);
      _recordingChanged.add(data['is_recording'] == true);
      _connectionStatus.add(SessionConnectionStatus.connected);
    });

    socket.on('session_error', (data) {
      final map = data is Map ? data : const {};
      final action = map['action']?.toString() ?? '';
      final message = map['error']?.toString() ?? 'Session error';
      _logger.w('session_error [$action]: $message');
      if (action == 'join_session') {
        _sessionError.add(message == 'Session not found'
            ? 'This lecture is not live yet.'
            : message);
        _connectionStatus.add(SessionConnectionStatus.error);
        socket.disconnect();
      } else {
        _sessionError.add(message);
      }
    });

    socket.on('rate_limited', (data) {
      _sessionError.add('You are sending messages too fast.');
    });

    // ---- transport -----------------------------------------------------
    socket.onDisconnect((reason) {
      _logger.w('Socket disconnected: $reason');
      if (reason == 'io client disconnect') return;
      _connectionStatus.add(SessionConnectionStatus.reconnecting);
      // Server-initiated disconnect (e.g. replaced by a newer login) does
      // not auto-reconnect — force it so the UI never sticks.
      if (reason == 'io server disconnect') socket.connect();
    });
    socket.onReconnectAttempt((_) {
      _connectionStatus.add(SessionConnectionStatus.reconnecting);
    });
    socket.onConnectError((error) {
      _logger.e('Socket connect error: $error');
      if (!_everConnected) {
        _connectionStatus.add(SessionConnectionStatus.reconnecting);
      }
    });
    socket.onError((error) {
      _logger.e('Socket error: $error');
    });

    // ---- room events ---------------------------------------------------
    socket.on('participant_joined', (data) {
      if (data is Map) _participantJoined.add(_participantFromSocket(data));
    });

    socket.on('participant_left', (data) {
      if (data is Map) _participantLeft.add(data['user_id'] as String? ?? '');
    });

    socket.on('chat_message', (data) {
      if (data is Map) _chatMessage.add(_chatMessageFromSocket(data));
    });

    socket.on('hand_raised', (data) {
      if (data is Map) _handRaised.add(_participantFromSocket(data));
    });

    socket.on('poll_created', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final options = (map['options'] as List? ?? const [])
            .map((e) => e is Map ? (e['text'] ?? e['label'] ?? '').toString() : e.toString())
            .toList();
        _pollStarted.add(ActivePoll(
          id: (map['poll_id'] ?? map['id'] ?? '').toString(),
          question: (map['question'] ?? '').toString(),
          options: options,
        ));
      }
    });

    socket.on('poll_ended', (data) {
      if (data is Map) _pollEnded.add(data['poll_id']?.toString() ?? '');
    });

    socket.on('recording_started', (_) => _recordingChanged.add(true));
    socket.on('recording_stopped', (_) => _recordingChanged.add(false));

    socket.on('muted', (data) {
      final by = data is Map ? (data['muted_by']?.toString() ?? '') : '';
      _muted.add(by);
    });

    socket.on('session_ended', (_) {
      _sessionEnded.add(null);
      _connectionStatus.add(SessionConnectionStatus.disconnected);
      socket.disconnect();
    });

    // ---- WebRTC signalling (relayed by the server, from_user_id is the
    // authenticated sender — the teacher) -------------------------------
    socket.on('webrtc_offer', (data) {
      if (data is Map) _webRtcOffer.add(Map<String, dynamic>.from(data));
    });
    socket.on('webrtc_answer', (data) {
      if (data is Map) _webRtcAnswer.add(Map<String, dynamic>.from(data));
    });
    socket.on('webrtc_ice_candidate', (data) {
      if (data is Map) _iceCandidate.add(Map<String, dynamic>.from(data));
    });
  }

  Map<String, dynamic> _base() => {
        'token': _authToken,
        'session_id': _sessionId,
      };

  void sendChatMessage(String content) {
    _socket?.emit('chat_message', {
      ..._base(),
      'user_id': _studentId,
      'user_name': _studentName,
      'message': content,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void raiseHand() {
    _socket?.emit('hand_raised', {
      ..._base(),
      'user_id': _studentId,
      'user_name': _studentName,
    });
  }

  void votePoll(String pollId, String option) {
    _socket?.emit('poll_response', {
      ..._base(),
      'poll_id': pollId,
      'option': option,
      'user_id': _studentId,
      'user_name': _studentName,
    });
  }

  /// [sdp] is `{type: 'answer', sdp: '...'}` — the shape simple-peer's
  /// `signal()` expects on the teacher's side.
  void sendAnswer(String targetId, Map<String, dynamic> sdp) {
    _socket?.emit('webrtc_answer', {
      ..._base(),
      'from_user_id': _studentId,
      'target_user_id': targetId,
      'sdp': sdp,
    });
  }

  void sendOffer(String targetId, Map<String, dynamic> sdp) {
    _socket?.emit('webrtc_offer', {
      ..._base(),
      'from_user_id': _studentId,
      'target_user_id': targetId,
      'sdp': sdp,
    });
  }

  /// [candidate] is `{candidate, sdpMid, sdpMLineIndex}`; wrapped the way
  /// simple-peer emits/consumes it: `{type: 'candidate', candidate: {...}}`.
  void sendIceCandidate(String targetId, Map<String, dynamic> candidate) {
    _socket?.emit('webrtc_ice_candidate', {
      ..._base(),
      'from_user_id': _studentId,
      'target_user_id': targetId,
      'candidate': {'type': 'candidate', 'candidate': candidate},
    });
  }

  void leaveSession() {
    _socket?.emit('leave_session', _base());
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
    _recordingChanged.close();
    _muted.close();
    _handRaised.close();
    _sessionError.close();
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
