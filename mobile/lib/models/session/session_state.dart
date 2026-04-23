import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';
part 'session_state.g.dart';

enum SessionMode { audio, video, text }
enum SessionConnectionStatus { connecting, connected, reconnecting, disconnected, error }

@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    required String sessionId,
    @Default(SessionConnectionStatus.connecting) SessionConnectionStatus connectionStatus,
    @Default(SessionMode.audio) SessionMode currentMode,
    @Default(<Participant>[]) List<Participant> participants,
    @Default(<ChatMessage>[]) List<ChatMessage> chatMessages,
    ActivePoll? activePoll,
    @Default(false) bool isMuted,
    @Default(false) bool isRecording,
    @Default(0.0) double audioLevel,
    String? errorMessage,
    @Default(0) int estimatedBandwidthKbps,
  }) = _SessionState;
}

@freezed
class Participant with _$Participant {
  const factory Participant({
    required String id,
    required String name,
    @Default('student') String role,
    @Default(false) bool isMuted,
    @Default(false) bool isSpeaking,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    required String senderName,
    required String content,
    required DateTime timestamp,
    @Default('student') String senderRole,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

@freezed
class ActivePoll with _$ActivePoll {
  const factory ActivePoll({
    required String id,
    required String question,
    required List<String> options,
    @Default(<String, int>{}) Map<String, int> votes,
    String? selectedOption,
  }) = _ActivePoll;

  factory ActivePoll.fromJson(Map<String, dynamic> json) =>
      _$ActivePollFromJson(json);
}

@freezed
class SessionParams with _$SessionParams {
  const factory SessionParams({
    required String sessionId,
    required String authToken,
    required String studentId,
    required String studentName,
  }) = _SessionParams;
}
