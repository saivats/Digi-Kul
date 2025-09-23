class ChatMessage {

  const ChatMessage({
    required this.id,
    this.lectureId,
    this.sessionId,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.message,
    required this.timestamp,
    this.isActive = true,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      lectureId: json['lecture_id'],
      sessionId: json['session_id'],
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userType: json['user_type'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String? lectureId;
  final String? sessionId;
  final String userId;
  final String userName;
  final String userType;
  final String message;
  final DateTime timestamp;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lecture_id': lectureId,
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      'user_type': userType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_active': isActive,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? lectureId,
    String? sessionId,
    String? userId,
    String? userName,
    String? userType,
    String? message,
    DateTime? timestamp,
    bool? isActive,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage{id: $id, userId: $userId, message: $message, timestamp: $timestamp}';
  }
}