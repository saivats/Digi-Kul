import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/storage/isar_service.dart';
import '../../../models/notification/cached_notification.dart';
import '../../../models/session/session_state.dart';
import '../services/bandwidth_monitor.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';

final sessionProvider = StateNotifierProvider.family
    .autoDispose<SessionNotifier, SessionState, SessionParams>(
  // StateNotifierProvider already calls notifier.dispose() on dispose; an
  // extra ref.onDispose would dispose it twice (StateNotifier asserts).
  (ref, params) => SessionNotifier(params: params),
);

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier({required SessionParams params})
      : _params = params,
        super(SessionState(sessionId: params.sessionId)) {
    _init();
  }

  final SessionParams _params;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // Lazily built so dispose() (which may run while runProbe is still
  // awaiting) never hits a LateInitializationError.
  late final SocketService _socketService = SocketService(
    sessionId: _params.sessionId,
    authToken: _params.authToken,
    studentId: _params.studentId,
    studentName: _params.studentName,
  );
  WebRtcService? _webRtcService;
  BandwidthMonitor? _bandwidthMonitor;
  String _teacherUserId = 'teacher';
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> _init() async {
    _bandwidthMonitor = BandwidthMonitor(
      authToken: _params.authToken,
      onModeRecommendation: _onModeRecommendation,
    );

    final bandwidth = await _bandwidthMonitor!.runProbe();
    if (!mounted) return; // screen left before the probe finished
    state = state.copyWith(estimatedBandwidthKbps: bandwidth);

    _subscriptions.addAll([
      _socketService.onConnectionStatus.listen((status) {
        state = state.copyWith(connectionStatus: status);
      }),
      _socketService.onParticipantJoined.listen((participant) {
        if (participant.role == 'teacher') {
          _teacherUserId = participant.id;
        }
        final updated = [
          ...state.participants.where((p) => p.id != participant.id),
          participant,
        ];
        state = state.copyWith(participants: updated);
      }),
      _socketService.onParticipantsSnapshot.listen((participants) {
        final teacher =
            participants.where((p) => p.role == 'teacher').firstOrNull;
        if (teacher != null) {
          _teacherUserId = teacher.id;
        }
        state = state.copyWith(participants: participants);
      }),
      _socketService.onParticipantLeft.listen((id) {
        final updated = state.participants.where((p) => p.id != id).toList();
        state = state.copyWith(participants: updated);
      }),
      _socketService.onChatMessage.listen(_onChatMessage),
      _socketService.onWebRtcOffer.listen(_onWebRtcOffer),
      _socketService.onWebRtcAnswer.listen((data) {
        _webRtcService?.handleAnswerData(data);
      }),
      _socketService.onIceCandidate.listen((data) {
        _webRtcService?.addIceCandidateData(data);
      }),
      _socketService.onPollStarted.listen((poll) {
        state = state.copyWith(activePoll: poll);
      }),
      _socketService.onPollEnded.listen((_) {
        state = state.copyWith(activePoll: null);
      }),
      _socketService.onSessionEnded.listen((_) {
        state = state.copyWith(
          connectionStatus: SessionConnectionStatus.disconnected,
          sessionEnded: true,
        );
      }),
      _socketService.onRecordingChanged.listen((recording) {
        state = state.copyWith(isRecording: recording);
      }),
      _socketService.onMuted.listen((_) {
        state = state.copyWith(isMuted: true, mutedByTeacher: true);
      }),
      _socketService.onHandRaised.listen((p) {
        final updated = state.participants
            .map((x) => x.id == p.id ? x.copyWith(isSpeaking: true) : x)
            .toList();
        state = state.copyWith(participants: updated);
      }),
      _socketService.onSessionError.listen((message) {
        state = state.copyWith(errorMessage: message);
      }),
    ]);

    if (BandwidthMonitor.determineModeFromBandwidth(bandwidth) !=
        SessionMode.text) {
      await _initWebRtc();
    }

    await _socketService.connect();

    if (!mounted) return;
    _bandwidthMonitor!.startPeriodicMonitoring();
  }

  Future<void> _initWebRtc() async {
    try {
      _webRtcService = WebRtcService(
        onIceCandidate: (candidate) {
          _socketService.sendIceCandidate(_teacherUserId, candidate.toMap());
        },
      );

      await _webRtcService!.initialize();
    } catch (e) {
      _logger.e('WebRTC init failed, falling back to text: $e');
      state = state.copyWith(currentMode: SessionMode.text);
    }
  }

  void _onChatMessage(ChatMessage message) {
    final updated = [...state.chatMessages, message];
    state = state.copyWith(chatMessages: updated);
    _persistChatMessage(message);
  }

  Future<void> _persistChatMessage(ChatMessage message) async {
    try {
      final isar = await IsarService.instance;
      final notification = CachedNotification()
        ..serverId = message.id
        ..title = 'Chat: ${message.senderName}'
        ..message = message.content
        ..type = 'session_chat'
        ..createdAt = message.timestamp
        ..isRead = true;

      await isar.writeTxn(() async {
        await isar.cachedNotifications.put(notification);
      });
    } catch (e) {
      _logger.w('Failed to persist chat message: $e');
    }
  }

  void _onModeRecommendation(SessionMode mode) {
    if (!mounted) return;
    if (mode != state.currentMode) {
      _logger.i('Bandwidth recommends mode: ${mode.name}');
      state = state.copyWith(
        currentMode: mode,
        estimatedBandwidthKbps: _bandwidthMonitor?.lastEstimateKbps ?? 0,
      );
    }
  }

  Future<void> _onWebRtcOffer(Map<String, dynamic> data) async {
    try {
      final fromUserId = data['from_user_id'] as String?;
      if (fromUserId != null && fromUserId.isNotEmpty) {
        _teacherUserId = fromUserId;
      }

      if (_webRtcService == null) {
        _webRtcService = WebRtcService(
          onIceCandidate: (candidate) {
            _socketService.sendIceCandidate(_teacherUserId, candidate.toMap());
          },
        );
        await _webRtcService!.initialize();
      }

      final answer = await _webRtcService!.handleOffer(data);
      if (answer != null) {
        _socketService.sendAnswer(_teacherUserId, answer.toMap());
      }
    } catch (e) {
      _logger.e('Failed to handle WebRTC offer: $e');
      state = state.copyWith(currentMode: SessionMode.text);
    }
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    _socketService.sendChatMessage(content);
  }

  void votePoll(String pollId, String option) {
    _socketService.votePoll(pollId, option);
    final poll = state.activePoll;
    if (poll != null) {
      state = state.copyWith(
        activePoll: poll.copyWith(selectedOption: option),
      );
    }
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void raiseHand() {
    _socketService.raiseHand();
    state = state.copyWith(handRaised: true);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void leaveSession() {
    _socketService.leaveSession();
    state = state.copyWith(
      connectionStatus: SessionConnectionStatus.disconnected,
    );
  }

  @override
  void dispose() {
    leaveSession();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _bandwidthMonitor?.dispose();
    _webRtcService?.dispose();
    _socketService.dispose();
    super.dispose();
  }
}
