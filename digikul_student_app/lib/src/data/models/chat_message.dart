import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// Chat message model for live session discussions
@JsonSerializable()
class ChatMessage extends Equatable {
  final String id;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'lecture_id')
  final String? lectureId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'user_type')
  final String userType;
  @JsonKey(name: 'user_name')
  final String userName;
  final String message;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional metadata
  final Map<String, dynamic>? metadata;
  
  // Local message state
  @JsonKey(includeFromJson: false, includeToJson: false)
  final MessageStatus status;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? tempId;

  const ChatMessage({
    required this.id,
    this.sessionId,
    this.lectureId,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.message,
    this.messageType = MessageType.text,
    required this.createdAt,
    this.isActive = true,
    this.metadata,
    this.status = MessageStatus.sent,
    this.tempId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? lectureId,
    String? userId,
    String? userType,
    String? userName,
    String? message,
    MessageType? messageType,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    String? tempId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lectureId: lectureId ?? this.lectureId,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      tempId: tempId ?? this.tempId,
    );
  }

  /// Check if the message is from a student
  bool get isFromStudent => userType == 'student';

  /// Check if the message is from a teacher
  bool get isFromTeacher => userType == 'teacher';

  /// Check if the message is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Check if the message is an announcement
  bool get isAnnouncement => messageType == MessageType.announcement;

  /// Check if the message is a poll
  bool get isPoll => messageType == MessageType.poll;

  /// Check if the message is a quiz
  bool get isQuiz => messageType == MessageType.quiz;

  /// Get display name with role indicator
  String get displayName {
    if (isSystemMessage) return 'System';
    if (isFromTeacher) return '$userName (Teacher)';
    return userName;
  }

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        lectureId,
        userId,
        userType,
        userName,
        message,
        messageType,
        createdAt,
        isActive,
        metadata,
        status,
        tempId,
      ];

  @override
  String toString() {
    return 'ChatMessage{id: $id, user: $userName, type: $messageType, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}}';
  }
}

/// Message types
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('system')
  system,
  @JsonValue('announcement')
  announcement,
  @JsonValue('poll')
  poll,
  @JsonValue('quiz')
  quiz,
  @JsonValue('file')
  file,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
}

/// Message status for local state management
enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
  deleted,
}

/// Chat message request for sending messages
@JsonSerializable()
class ChatMessageRequest extends Equatable {
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'lecture_id')
  final String? lectureId;
  final String message;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final Map<String, dynamic>? metadata;

  const ChatMessageRequest({
    this.sessionId,
    this.lectureId,
    required this.message,
    this.messageType = MessageType.text,
    this.metadata,
  });

  factory ChatMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageRequestToJson(this);

  @override
  List<Object?> get props => [sessionId, lectureId, message, messageType, metadata];
}

/// System message types for different events
enum SystemMessageType {
  userJoined,
  userLeft,
  sessionStarted,
  sessionEnded,
  pollCreated,
  quizCreated,
  materialShared,
  recordingStarted,
  recordingStopped,
}

/// Factory for creating system messages
class SystemMessage {
  static ChatMessage userJoined(String userName) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: '$userName joined the session',
      messageType: MessageType.system,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'user_joined',
        'user_name': userName,
      },
    );
  }

  static ChatMessage userLeft(String userName) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: '$userName left the session',
      messageType: MessageType.system,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'user_left',
        'user_name': userName,
      },
    );
  }

  static ChatMessage sessionStarted() {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: 'Live session has started',
      messageType: MessageType.system,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'session_started',
      },
    );
  }

  static ChatMessage sessionEnded() {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: 'Live session has ended',
      messageType: MessageType.system,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'session_ended',
      },
    );
  }

  static ChatMessage pollCreated(String pollQuestion) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: 'New poll: $pollQuestion',
      messageType: MessageType.poll,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'poll_created',
        'poll_question': pollQuestion,
      },
    );
  }

  static ChatMessage materialShared(String materialTitle) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      userType: 'system',
      userName: 'System',
      message: 'New material shared: $materialTitle',
      messageType: MessageType.system,
      createdAt: DateTime.now(),
      metadata: {
        'system_type': 'material_shared',
        'material_title': materialTitle,
      },
    );
  }
}

/// Chat statistics for session management
@JsonSerializable()
class ChatStatistics extends Equatable {
  @JsonKey(name: 'total_messages')
  final int totalMessages;
  @JsonKey(name: 'student_messages')
  final int studentMessages;
  @JsonKey(name: 'teacher_messages')
  final int teacherMessages;
  @JsonKey(name: 'system_messages')
  final int systemMessages;
  @JsonKey(name: 'active_participants')
  final int activeParticipants;
  @JsonKey(name: 'last_activity')
  final DateTime? lastActivity;

  const ChatStatistics({
    this.totalMessages = 0,
    this.studentMessages = 0,
    this.teacherMessages = 0,
    this.systemMessages = 0,
    this.activeParticipants = 0,
    this.lastActivity,
  });

  factory ChatStatistics.fromJson(Map<String, dynamic> json) =>
      _$ChatStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ChatStatisticsToJson(this);

  @override
  List<Object?> get props => [
        totalMessages,
        studentMessages,
        teacherMessages,
        systemMessages,
        activeParticipants,
        lastActivity,
      ];
}
