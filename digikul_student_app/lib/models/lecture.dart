class Lecture {

  const Lecture({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.scheduledAt,
    required this.duration,
    required this.createdAt,
    this.isActive = true,
    this.teacherName,
    this.teacherInstitution,
    this.sessionActive = false,
    this.canJoin = false,
    this.enrolledAt,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at'] ?? '') ?? DateTime.now(),
      duration: json['duration'] ?? 60,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
      teacherName: json['teacher_name'],
      teacherInstitution: json['teacher_institution'],
      sessionActive: json['session_active'] ?? false,
      canJoin: json['can_join'] ?? false,
      enrolledAt: json['enrolled_at'] != null ? DateTime.tryParse(json['enrolled_at']) : null,
    );
  }
  final String id;
  final String title;
  final String description;
  final String teacherId;
  final DateTime scheduledAt;
  final int duration; // in minutes
  final DateTime createdAt;
  final bool isActive;
  
  // Additional fields from API responses
  final String? teacherName;
  final String? teacherInstitution;
  final bool sessionActive;
  final bool canJoin;
  final DateTime? enrolledAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'teacher_name': teacherName,
      'teacher_institution': teacherInstitution,
      'session_active': sessionActive,
      'can_join': canJoin,
      'enrolled_at': enrolledAt?.toIso8601String(),
    };
  }

  Lecture copyWith({
    String? id,
    String? title,
    String? description,
    String? teacherId,
    DateTime? scheduledAt,
    int? duration,
    DateTime? createdAt,
    bool? isActive,
    String? teacherName,
    String? teacherInstitution,
    bool? sessionActive,
    bool? canJoin,
    DateTime? enrolledAt,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      teacherName: teacherName ?? this.teacherName,
      teacherInstitution: teacherInstitution ?? this.teacherInstitution,
      sessionActive: sessionActive ?? this.sessionActive,
      canJoin: canJoin ?? this.canJoin,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }

  // Computed properties for UI
  bool get isLive => sessionActive;
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && !sessionActive;
  bool get isPast => scheduledAt.isBefore(DateTime.now()) && !sessionActive;
  bool get isOngoing => sessionActive && scheduledAt.isBefore(DateTime.now());
  
  String get displayTeacherName => teacherName ?? 'Unknown Teacher';
  Duration get durationDuration => Duration(minutes: duration);
  DateTime get endTime => scheduledAt.add(Duration(minutes: duration));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lecture && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Lecture{id: $id, title: $title, teacherId: $teacherId, scheduledAt: $scheduledAt}';
  }
}