import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lecture.g.dart';

/// Lecture model representing a scheduled educational session
@JsonSerializable()
class Lecture extends Equatable {
  final String id;
  @JsonKey(name: 'teacher_id')
  final String teacherId;
  final String title;
  final String? description;
  @JsonKey(name: 'scheduled_time')
  final DateTime scheduledTime;
  final int duration; // Duration in minutes
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'teacher_institution')
  final String? teacherInstitution;
  @JsonKey(name: 'session_active')
  final bool? sessionActive;
  @JsonKey(name: 'can_join')
  final bool? canJoin;
  @JsonKey(name: 'enrolled_at')
  final DateTime? enrolledAt;

  const Lecture({
    required this.id,
    required this.teacherId,
    required this.title,
    this.description,
    required this.scheduledTime,
    required this.duration,
    required this.createdAt,
    this.isActive = true,
    this.teacherName,
    this.teacherInstitution,
    this.sessionActive,
    this.canJoin,
    this.enrolledAt,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) => _$LectureFromJson(json);

  Map<String, dynamic> toJson() => _$LectureToJson(this);

  Lecture copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? description,
    DateTime? scheduledTime,
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
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
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

  /// Check if the lecture is currently live
  bool get isLive {
    final now = DateTime.now();
    final endTime = scheduledTime.add(Duration(minutes: duration));
    return sessionActive == true && 
           now.isAfter(scheduledTime) && 
           now.isBefore(endTime);
  }

  /// Check if the lecture is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(scheduledTime);
  }

  /// Check if the lecture has ended
  bool get hasEnded {
    final now = DateTime.now();
    final endTime = scheduledTime.add(Duration(minutes: duration));
    return now.isAfter(endTime);
  }

  /// Get the lecture status
  String get status {
    if (isLive) return 'live';
    if (isUpcoming) return 'upcoming';
    if (hasEnded) return 'ended';
    return 'unknown';
  }

  /// Get the end time of the lecture
  DateTime get endTime => scheduledTime.add(Duration(minutes: duration));

  /// Get duration in hours and minutes format
  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        id,
        teacherId,
        title,
        description,
        scheduledTime,
        duration,
        createdAt,
        isActive,
        teacherName,
        teacherInstitution,
        sessionActive,
        canJoin,
        enrolledAt,
      ];

  @override
  String toString() {
    return 'Lecture{id: $id, title: $title, teacher: $teacherName, scheduled: $scheduledTime}';
  }
}

/// Lecture summary for list views
@JsonSerializable()
class LectureSummary extends Equatable {
  final String id;
  final String title;
  final String? teacherName;
  final DateTime scheduledTime;
  final int duration;
  final bool isLive;
  final bool isEnrolled;

  const LectureSummary({
    required this.id,
    required this.title,
    this.teacherName,
    required this.scheduledTime,
    required this.duration,
    this.isLive = false,
    this.isEnrolled = false,
  });

  factory LectureSummary.fromJson(Map<String, dynamic> json) =>
      _$LectureSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$LectureSummaryToJson(this);

  factory LectureSummary.fromLecture(Lecture lecture) {
    return LectureSummary(
      id: lecture.id,
      title: lecture.title,
      teacherName: lecture.teacherName,
      scheduledTime: lecture.scheduledTime,
      duration: lecture.duration,
      isLive: lecture.isLive,
      isEnrolled: lecture.enrolledAt != null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        teacherName,
        scheduledTime,
        duration,
        isLive,
        isEnrolled,
      ];
}

/// Lecture details with additional information
@JsonSerializable()
class LectureDetails extends Lecture {
  final int enrolledStudents;
  final List<String>? materials;
  final List<String>? polls;
  final String? sessionId;

  const LectureDetails({
    required String id,
    required String teacherId,
    required String title,
    String? description,
    required DateTime scheduledTime,
    required int duration,
    required DateTime createdAt,
    bool isActive = true,
    String? teacherName,
    String? teacherInstitution,
    bool? sessionActive,
    bool? canJoin,
    DateTime? enrolledAt,
    this.enrolledStudents = 0,
    this.materials,
    this.polls,
    this.sessionId,
  }) : super(
          id: id,
          teacherId: teacherId,
          title: title,
          description: description,
          scheduledTime: scheduledTime,
          duration: duration,
          createdAt: createdAt,
          isActive: isActive,
          teacherName: teacherName,
          teacherInstitution: teacherInstitution,
          sessionActive: sessionActive,
          canJoin: canJoin,
          enrolledAt: enrolledAt,
        );

  factory LectureDetails.fromJson(Map<String, dynamic> json) =>
      _$LectureDetailsFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LectureDetailsToJson(this);

  @override
  LectureDetails copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    int? duration,
    DateTime? createdAt,
    bool? isActive,
    String? teacherName,
    String? teacherInstitution,
    bool? sessionActive,
    bool? canJoin,
    DateTime? enrolledAt,
    int? enrolledStudents,
    List<String>? materials,
    List<String>? polls,
    String? sessionId,
  }) {
    return LectureDetails(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      teacherName: teacherName ?? this.teacherName,
      teacherInstitution: teacherInstitution ?? this.teacherInstitution,
      sessionActive: sessionActive ?? this.sessionActive,
      canJoin: canJoin ?? this.canJoin,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      materials: materials ?? this.materials,
      polls: polls ?? this.polls,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        enrolledStudents,
        materials,
        polls,
        sessionId,
      ];
}
