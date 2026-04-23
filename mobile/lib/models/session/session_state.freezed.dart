// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SessionState {
  String get sessionId => throw _privateConstructorUsedError;
  SessionConnectionStatus get connectionStatus =>
      throw _privateConstructorUsedError;
  SessionMode get currentMode => throw _privateConstructorUsedError;
  List<Participant> get participants => throw _privateConstructorUsedError;
  List<ChatMessage> get chatMessages => throw _privateConstructorUsedError;
  ActivePoll? get activePoll => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  bool get isRecording => throw _privateConstructorUsedError;
  double get audioLevel => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  int get estimatedBandwidthKbps => throw _privateConstructorUsedError;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionStateCopyWith<SessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionStateCopyWith<$Res> {
  factory $SessionStateCopyWith(
          SessionState value, $Res Function(SessionState) then) =
      _$SessionStateCopyWithImpl<$Res, SessionState>;
  @useResult
  $Res call(
      {String sessionId,
      SessionConnectionStatus connectionStatus,
      SessionMode currentMode,
      List<Participant> participants,
      List<ChatMessage> chatMessages,
      ActivePoll? activePoll,
      bool isMuted,
      bool isRecording,
      double audioLevel,
      String? errorMessage,
      int estimatedBandwidthKbps});

  $ActivePollCopyWith<$Res>? get activePoll;
}

/// @nodoc
class _$SessionStateCopyWithImpl<$Res, $Val extends SessionState>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? connectionStatus = null,
    Object? currentMode = null,
    Object? participants = null,
    Object? chatMessages = null,
    Object? activePoll = freezed,
    Object? isMuted = null,
    Object? isRecording = null,
    Object? audioLevel = null,
    Object? errorMessage = freezed,
    Object? estimatedBandwidthKbps = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      connectionStatus: null == connectionStatus
          ? _value.connectionStatus
          : connectionStatus // ignore: cast_nullable_to_non_nullable
              as SessionConnectionStatus,
      currentMode: null == currentMode
          ? _value.currentMode
          : currentMode // ignore: cast_nullable_to_non_nullable
              as SessionMode,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<Participant>,
      chatMessages: null == chatMessages
          ? _value.chatMessages
          : chatMessages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      activePoll: freezed == activePoll
          ? _value.activePoll
          : activePoll // ignore: cast_nullable_to_non_nullable
              as ActivePoll?,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isRecording: null == isRecording
          ? _value.isRecording
          : isRecording // ignore: cast_nullable_to_non_nullable
              as bool,
      audioLevel: null == audioLevel
          ? _value.audioLevel
          : audioLevel // ignore: cast_nullable_to_non_nullable
              as double,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedBandwidthKbps: null == estimatedBandwidthKbps
          ? _value.estimatedBandwidthKbps
          : estimatedBandwidthKbps // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActivePollCopyWith<$Res>? get activePoll {
    if (_value.activePoll == null) {
      return null;
    }

    return $ActivePollCopyWith<$Res>(_value.activePoll!, (value) {
      return _then(_value.copyWith(activePoll: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SessionStateImplCopyWith<$Res>
    implements $SessionStateCopyWith<$Res> {
  factory _$$SessionStateImplCopyWith(
          _$SessionStateImpl value, $Res Function(_$SessionStateImpl) then) =
      __$$SessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sessionId,
      SessionConnectionStatus connectionStatus,
      SessionMode currentMode,
      List<Participant> participants,
      List<ChatMessage> chatMessages,
      ActivePoll? activePoll,
      bool isMuted,
      bool isRecording,
      double audioLevel,
      String? errorMessage,
      int estimatedBandwidthKbps});

  @override
  $ActivePollCopyWith<$Res>? get activePoll;
}

/// @nodoc
class __$$SessionStateImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionStateImpl>
    implements _$$SessionStateImplCopyWith<$Res> {
  __$$SessionStateImplCopyWithImpl(
      _$SessionStateImpl _value, $Res Function(_$SessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? connectionStatus = null,
    Object? currentMode = null,
    Object? participants = null,
    Object? chatMessages = null,
    Object? activePoll = freezed,
    Object? isMuted = null,
    Object? isRecording = null,
    Object? audioLevel = null,
    Object? errorMessage = freezed,
    Object? estimatedBandwidthKbps = null,
  }) {
    return _then(_$SessionStateImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      connectionStatus: null == connectionStatus
          ? _value.connectionStatus
          : connectionStatus // ignore: cast_nullable_to_non_nullable
              as SessionConnectionStatus,
      currentMode: null == currentMode
          ? _value.currentMode
          : currentMode // ignore: cast_nullable_to_non_nullable
              as SessionMode,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<Participant>,
      chatMessages: null == chatMessages
          ? _value._chatMessages
          : chatMessages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      activePoll: freezed == activePoll
          ? _value.activePoll
          : activePoll // ignore: cast_nullable_to_non_nullable
              as ActivePoll?,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isRecording: null == isRecording
          ? _value.isRecording
          : isRecording // ignore: cast_nullable_to_non_nullable
              as bool,
      audioLevel: null == audioLevel
          ? _value.audioLevel
          : audioLevel // ignore: cast_nullable_to_non_nullable
              as double,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedBandwidthKbps: null == estimatedBandwidthKbps
          ? _value.estimatedBandwidthKbps
          : estimatedBandwidthKbps // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SessionStateImpl implements _SessionState {
  const _$SessionStateImpl(
      {required this.sessionId,
      this.connectionStatus = SessionConnectionStatus.connecting,
      this.currentMode = SessionMode.audio,
      final List<Participant> participants = const <Participant>[],
      final List<ChatMessage> chatMessages = const <ChatMessage>[],
      this.activePoll,
      this.isMuted = false,
      this.isRecording = false,
      this.audioLevel = 0.0,
      this.errorMessage,
      this.estimatedBandwidthKbps = 0})
      : _participants = participants,
        _chatMessages = chatMessages;

  @override
  final String sessionId;
  @override
  @JsonKey()
  final SessionConnectionStatus connectionStatus;
  @override
  @JsonKey()
  final SessionMode currentMode;
  final List<Participant> _participants;
  @override
  @JsonKey()
  List<Participant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  final List<ChatMessage> _chatMessages;
  @override
  @JsonKey()
  List<ChatMessage> get chatMessages {
    if (_chatMessages is EqualUnmodifiableListView) return _chatMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chatMessages);
  }

  @override
  final ActivePoll? activePoll;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  @JsonKey()
  final bool isRecording;
  @override
  @JsonKey()
  final double audioLevel;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final int estimatedBandwidthKbps;

  @override
  String toString() {
    return 'SessionState(sessionId: $sessionId, connectionStatus: $connectionStatus, currentMode: $currentMode, participants: $participants, chatMessages: $chatMessages, activePoll: $activePoll, isMuted: $isMuted, isRecording: $isRecording, audioLevel: $audioLevel, errorMessage: $errorMessage, estimatedBandwidthKbps: $estimatedBandwidthKbps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionStateImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.connectionStatus, connectionStatus) ||
                other.connectionStatus == connectionStatus) &&
            (identical(other.currentMode, currentMode) ||
                other.currentMode == currentMode) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            const DeepCollectionEquality()
                .equals(other._chatMessages, _chatMessages) &&
            (identical(other.activePoll, activePoll) ||
                other.activePoll == activePoll) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.isRecording, isRecording) ||
                other.isRecording == isRecording) &&
            (identical(other.audioLevel, audioLevel) ||
                other.audioLevel == audioLevel) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.estimatedBandwidthKbps, estimatedBandwidthKbps) ||
                other.estimatedBandwidthKbps == estimatedBandwidthKbps));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      sessionId,
      connectionStatus,
      currentMode,
      const DeepCollectionEquality().hash(_participants),
      const DeepCollectionEquality().hash(_chatMessages),
      activePoll,
      isMuted,
      isRecording,
      audioLevel,
      errorMessage,
      estimatedBandwidthKbps);

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      __$$SessionStateImplCopyWithImpl<_$SessionStateImpl>(this, _$identity);
}

abstract class _SessionState implements SessionState {
  const factory _SessionState(
      {required final String sessionId,
      final SessionConnectionStatus connectionStatus,
      final SessionMode currentMode,
      final List<Participant> participants,
      final List<ChatMessage> chatMessages,
      final ActivePoll? activePoll,
      final bool isMuted,
      final bool isRecording,
      final double audioLevel,
      final String? errorMessage,
      final int estimatedBandwidthKbps}) = _$SessionStateImpl;

  @override
  String get sessionId;
  @override
  SessionConnectionStatus get connectionStatus;
  @override
  SessionMode get currentMode;
  @override
  List<Participant> get participants;
  @override
  List<ChatMessage> get chatMessages;
  @override
  ActivePoll? get activePoll;
  @override
  bool get isMuted;
  @override
  bool get isRecording;
  @override
  double get audioLevel;
  @override
  String? get errorMessage;
  @override
  int get estimatedBandwidthKbps;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Participant _$ParticipantFromJson(Map<String, dynamic> json) {
  return _Participant.fromJson(json);
}

/// @nodoc
mixin _$Participant {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  bool get isSpeaking => throw _privateConstructorUsedError;

  /// Serializes this Participant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipantCopyWith<Participant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipantCopyWith<$Res> {
  factory $ParticipantCopyWith(
          Participant value, $Res Function(Participant) then) =
      _$ParticipantCopyWithImpl<$Res, Participant>;
  @useResult
  $Res call(
      {String id, String name, String role, bool isMuted, bool isSpeaking});
}

/// @nodoc
class _$ParticipantCopyWithImpl<$Res, $Val extends Participant>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? role = null,
    Object? isMuted = null,
    Object? isSpeaking = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isSpeaking: null == isSpeaking
          ? _value.isSpeaking
          : isSpeaking // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ParticipantImplCopyWith<$Res>
    implements $ParticipantCopyWith<$Res> {
  factory _$$ParticipantImplCopyWith(
          _$ParticipantImpl value, $Res Function(_$ParticipantImpl) then) =
      __$$ParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, String role, bool isMuted, bool isSpeaking});
}

/// @nodoc
class __$$ParticipantImplCopyWithImpl<$Res>
    extends _$ParticipantCopyWithImpl<$Res, _$ParticipantImpl>
    implements _$$ParticipantImplCopyWith<$Res> {
  __$$ParticipantImplCopyWithImpl(
      _$ParticipantImpl _value, $Res Function(_$ParticipantImpl) _then)
      : super(_value, _then);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? role = null,
    Object? isMuted = null,
    Object? isSpeaking = null,
  }) {
    return _then(_$ParticipantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isSpeaking: null == isSpeaking
          ? _value.isSpeaking
          : isSpeaking // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ParticipantImpl implements _Participant {
  const _$ParticipantImpl(
      {required this.id,
      required this.name,
      this.role = 'student',
      this.isMuted = false,
      this.isSpeaking = false});

  factory _$ParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParticipantImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  @JsonKey()
  final bool isSpeaking;

  @override
  String toString() {
    return 'Participant(id: $id, name: $name, role: $role, isMuted: $isMuted, isSpeaking: $isSpeaking)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.isSpeaking, isSpeaking) ||
                other.isSpeaking == isSpeaking));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, role, isMuted, isSpeaking);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      __$$ParticipantImplCopyWithImpl<_$ParticipantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParticipantImplToJson(
      this,
    );
  }
}

abstract class _Participant implements Participant {
  const factory _Participant(
      {required final String id,
      required final String name,
      final String role,
      final bool isMuted,
      final bool isSpeaking}) = _$ParticipantImpl;

  factory _Participant.fromJson(Map<String, dynamic> json) =
      _$ParticipantImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get role;
  @override
  bool get isMuted;
  @override
  bool get isSpeaking;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get senderName => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get senderRole => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String senderName,
      String content,
      DateTime timestamp,
      String senderRole});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? content = null,
    Object? timestamp = null,
    Object? senderRole = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderRole: null == senderRole
          ? _value.senderRole
          : senderRole // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String senderName,
      String content,
      DateTime timestamp,
      String senderRole});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? content = null,
    Object? timestamp = null,
    Object? senderRole = null,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderRole: null == senderRole
          ? _value.senderRole
          : senderRole // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.senderId,
      required this.senderName,
      required this.content,
      required this.timestamp,
      this.senderRole = 'student'});

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String senderName;
  @override
  final String content;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final String senderRole;

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, senderName: $senderName, content: $content, timestamp: $timestamp, senderRole: $senderRole)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.senderRole, senderRole) ||
                other.senderRole == senderRole));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, senderId, senderName, content, timestamp, senderRole);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String senderId,
      required final String senderName,
      required final String content,
      required final DateTime timestamp,
      final String senderRole}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String get senderName;
  @override
  String get content;
  @override
  DateTime get timestamp;
  @override
  String get senderRole;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActivePoll _$ActivePollFromJson(Map<String, dynamic> json) {
  return _ActivePoll.fromJson(json);
}

/// @nodoc
mixin _$ActivePoll {
  String get id => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  List<String> get options => throw _privateConstructorUsedError;
  Map<String, int> get votes => throw _privateConstructorUsedError;
  String? get selectedOption => throw _privateConstructorUsedError;

  /// Serializes this ActivePoll to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActivePoll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivePollCopyWith<ActivePoll> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivePollCopyWith<$Res> {
  factory $ActivePollCopyWith(
          ActivePoll value, $Res Function(ActivePoll) then) =
      _$ActivePollCopyWithImpl<$Res, ActivePoll>;
  @useResult
  $Res call(
      {String id,
      String question,
      List<String> options,
      Map<String, int> votes,
      String? selectedOption});
}

/// @nodoc
class _$ActivePollCopyWithImpl<$Res, $Val extends ActivePoll>
    implements $ActivePollCopyWith<$Res> {
  _$ActivePollCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivePoll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? question = null,
    Object? options = null,
    Object? votes = null,
    Object? selectedOption = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      votes: null == votes
          ? _value.votes
          : votes // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      selectedOption: freezed == selectedOption
          ? _value.selectedOption
          : selectedOption // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivePollImplCopyWith<$Res>
    implements $ActivePollCopyWith<$Res> {
  factory _$$ActivePollImplCopyWith(
          _$ActivePollImpl value, $Res Function(_$ActivePollImpl) then) =
      __$$ActivePollImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String question,
      List<String> options,
      Map<String, int> votes,
      String? selectedOption});
}

/// @nodoc
class __$$ActivePollImplCopyWithImpl<$Res>
    extends _$ActivePollCopyWithImpl<$Res, _$ActivePollImpl>
    implements _$$ActivePollImplCopyWith<$Res> {
  __$$ActivePollImplCopyWithImpl(
      _$ActivePollImpl _value, $Res Function(_$ActivePollImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActivePoll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? question = null,
    Object? options = null,
    Object? votes = null,
    Object? selectedOption = freezed,
  }) {
    return _then(_$ActivePollImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      votes: null == votes
          ? _value._votes
          : votes // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      selectedOption: freezed == selectedOption
          ? _value.selectedOption
          : selectedOption // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActivePollImpl implements _ActivePoll {
  const _$ActivePollImpl(
      {required this.id,
      required this.question,
      required final List<String> options,
      final Map<String, int> votes = const <String, int>{},
      this.selectedOption})
      : _options = options,
        _votes = votes;

  factory _$ActivePollImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActivePollImplFromJson(json);

  @override
  final String id;
  @override
  final String question;
  final List<String> _options;
  @override
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final Map<String, int> _votes;
  @override
  @JsonKey()
  Map<String, int> get votes {
    if (_votes is EqualUnmodifiableMapView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_votes);
  }

  @override
  final String? selectedOption;

  @override
  String toString() {
    return 'ActivePoll(id: $id, question: $question, options: $options, votes: $votes, selectedOption: $selectedOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivePollImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.question, question) ||
                other.question == question) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            (identical(other.selectedOption, selectedOption) ||
                other.selectedOption == selectedOption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      question,
      const DeepCollectionEquality().hash(_options),
      const DeepCollectionEquality().hash(_votes),
      selectedOption);

  /// Create a copy of ActivePoll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivePollImplCopyWith<_$ActivePollImpl> get copyWith =>
      __$$ActivePollImplCopyWithImpl<_$ActivePollImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActivePollImplToJson(
      this,
    );
  }
}

abstract class _ActivePoll implements ActivePoll {
  const factory _ActivePoll(
      {required final String id,
      required final String question,
      required final List<String> options,
      final Map<String, int> votes,
      final String? selectedOption}) = _$ActivePollImpl;

  factory _ActivePoll.fromJson(Map<String, dynamic> json) =
      _$ActivePollImpl.fromJson;

  @override
  String get id;
  @override
  String get question;
  @override
  List<String> get options;
  @override
  Map<String, int> get votes;
  @override
  String? get selectedOption;

  /// Create a copy of ActivePoll
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivePollImplCopyWith<_$ActivePollImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SessionParams {
  String get sessionId => throw _privateConstructorUsedError;
  String get authToken => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;

  /// Create a copy of SessionParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionParamsCopyWith<SessionParams> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionParamsCopyWith<$Res> {
  factory $SessionParamsCopyWith(
          SessionParams value, $Res Function(SessionParams) then) =
      _$SessionParamsCopyWithImpl<$Res, SessionParams>;
  @useResult
  $Res call(
      {String sessionId,
      String authToken,
      String studentId,
      String studentName});
}

/// @nodoc
class _$SessionParamsCopyWithImpl<$Res, $Val extends SessionParams>
    implements $SessionParamsCopyWith<$Res> {
  _$SessionParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? authToken = null,
    Object? studentId = null,
    Object? studentName = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      authToken: null == authToken
          ? _value.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionParamsImplCopyWith<$Res>
    implements $SessionParamsCopyWith<$Res> {
  factory _$$SessionParamsImplCopyWith(
          _$SessionParamsImpl value, $Res Function(_$SessionParamsImpl) then) =
      __$$SessionParamsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sessionId,
      String authToken,
      String studentId,
      String studentName});
}

/// @nodoc
class __$$SessionParamsImplCopyWithImpl<$Res>
    extends _$SessionParamsCopyWithImpl<$Res, _$SessionParamsImpl>
    implements _$$SessionParamsImplCopyWith<$Res> {
  __$$SessionParamsImplCopyWithImpl(
      _$SessionParamsImpl _value, $Res Function(_$SessionParamsImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? authToken = null,
    Object? studentId = null,
    Object? studentName = null,
  }) {
    return _then(_$SessionParamsImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      authToken: null == authToken
          ? _value.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SessionParamsImpl implements _SessionParams {
  const _$SessionParamsImpl(
      {required this.sessionId,
      required this.authToken,
      required this.studentId,
      required this.studentName});

  @override
  final String sessionId;
  @override
  final String authToken;
  @override
  final String studentId;
  @override
  final String studentName;

  @override
  String toString() {
    return 'SessionParams(sessionId: $sessionId, authToken: $authToken, studentId: $studentId, studentName: $studentName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionParamsImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.authToken, authToken) ||
                other.authToken == authToken) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, sessionId, authToken, studentId, studentName);

  /// Create a copy of SessionParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionParamsImplCopyWith<_$SessionParamsImpl> get copyWith =>
      __$$SessionParamsImplCopyWithImpl<_$SessionParamsImpl>(this, _$identity);
}

abstract class _SessionParams implements SessionParams {
  const factory _SessionParams(
      {required final String sessionId,
      required final String authToken,
      required final String studentId,
      required final String studentName}) = _$SessionParamsImpl;

  @override
  String get sessionId;
  @override
  String get authToken;
  @override
  String get studentId;
  @override
  String get studentName;

  /// Create a copy of SessionParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionParamsImplCopyWith<_$SessionParamsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
