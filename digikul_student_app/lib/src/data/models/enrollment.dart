import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment.g.dart';

/// Enrollment model representing student enrollment in lectures
@JsonSerializable()
class Enrollment extends Equatable {
  final String id;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'lecture_id')
  final String lectureId;
  @JsonKey(name: 'enrolled_at')
  final DateTime enrolledAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'lecture_title')
  final String? lectureTitle;
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'scheduled_time')
  final DateTime? scheduledTime;
  @JsonKey(name: 'duration')
  final int? duration;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.lectureId,
    required this.enrolledAt,
    this.isActive = true,
    this.lectureTitle,
    this.teacherName,
    this.scheduledTime,
    this.duration,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentToJson(this);

  Enrollment copyWith({
    String? id,
    String? studentId,
    String? lectureId,
    DateTime? enrolledAt,
    bool? isActive,
    String? lectureTitle,
    String? teacherName,
    DateTime? scheduledTime,
    int? duration,
  }) {
    return Enrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      lectureId: lectureId ?? this.lectureId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
      lectureTitle: lectureTitle ?? this.lectureTitle,
      teacherName: teacherName ?? this.teacherName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
    );
  }

  /// Check if the lecture is upcoming
  bool get isUpcoming {
    if (scheduledTime == null) return false;
    return DateTime.now().isBefore(scheduledTime!);
  }

  /// Check if the lecture is currently live
  bool get isLive {
    if (scheduledTime == null || duration == null) return false;
    final now = DateTime.now();
    final endTime = scheduledTime!.add(Duration(minutes: duration!));
    return now.isAfter(scheduledTime!) && now.isBefore(endTime);
  }

  /// Check if the lecture has ended
  bool get hasEnded {
    if (scheduledTime == null || duration == null) return false;
    final now = DateTime.now();
    final endTime = scheduledTime!.add(Duration(minutes: duration!));
    return now.isAfter(endTime);
  }

  /// Get the lecture status
  String get status {
    if (isLive) return 'live';
    if (isUpcoming) return 'upcoming';
    if (hasEnded) return 'ended';
    return 'unknown';
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        lectureId,
        enrolledAt,
        isActive,
        lectureTitle,
        teacherName,
        scheduledTime,
        duration,
      ];

  @override
  String toString() {
    return 'Enrollment{id: $id, lecture: $lectureTitle, enrolledAt: $enrolledAt}';
  }
}

/// Enrollment request model
@JsonSerializable()
class EnrollmentRequest extends Equatable {
  @JsonKey(name: 'lecture_id')
  final String lectureId;

  const EnrollmentRequest({
    required this.lectureId,
  });

  factory EnrollmentRequest.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentRequestToJson(this);

  @override
  List<Object?> get props => [lectureId];
}

/// Enrollment response model
@JsonSerializable()
class EnrollmentResponse extends Equatable {
  final bool success;
  final String message;
  @JsonKey(name: 'enrollment_id')
  final String? enrollmentId;
  @JsonKey(name: 'already_enrolled')
  final bool? alreadyEnrolled;

  const EnrollmentResponse({
    required this.success,
    required this.message,
    this.enrollmentId,
    this.alreadyEnrolled,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentResponseToJson(this);

  @override
  List<Object?> get props => [success, message, enrollmentId, alreadyEnrolled];
}

/// Enrollment summary for dashboard
@JsonSerializable()
class EnrollmentSummary extends Equatable {
  @JsonKey(name: 'total_enrollments')
  final int totalEnrollments;
  @JsonKey(name: 'active_enrollments')
  final int activeEnrollments;
  @JsonKey(name: 'upcoming_lectures')
  final int upcomingLectures;
  @JsonKey(name: 'live_lectures')
  final int liveLectures;
  @JsonKey(name: 'completed_lectures')
  final int completedLectures;

  const EnrollmentSummary({
    this.totalEnrollments = 0,
    this.activeEnrollments = 0,
    this.upcomingLectures = 0,
    this.liveLectures = 0,
    this.completedLectures = 0,
  });

  factory EnrollmentSummary.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentSummaryToJson(this);

  @override
  List<Object?> get props => [
        totalEnrollments,
        activeEnrollments,
        upcomingLectures,
        liveLectures,
        completedLectures,
      ];
}

/// Cohort enrollment model
@JsonSerializable()
class CohortEnrollment extends Equatable {
  final String id;
  @JsonKey(name: 'cohort_id')
  final String cohortId;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  
  // Additional fields from API responses
  @JsonKey(name: 'cohort_name')
  final String? cohortName;
  @JsonKey(name: 'cohort_subject')
  final String? cohortSubject;
  @JsonKey(name: 'teacher_name')
  final String? teacherName;

  const CohortEnrollment({
    required this.id,
    required this.cohortId,
    required this.studentId,
    required this.joinedAt,
    this.cohortName,
    this.cohortSubject,
    this.teacherName,
  });

  factory CohortEnrollment.fromJson(Map<String, dynamic> json) =>
      _$CohortEnrollmentFromJson(json);

  Map<String, dynamic> toJson() => _$CohortEnrollmentToJson(this);

  CohortEnrollment copyWith({
    String? id,
    String? cohortId,
    String? studentId,
    DateTime? joinedAt,
    String? cohortName,
    String? cohortSubject,
    String? teacherName,
  }) {
    return CohortEnrollment(
      id: id ?? this.id,
      cohortId: cohortId ?? this.cohortId,
      studentId: studentId ?? this.studentId,
      joinedAt: joinedAt ?? this.joinedAt,
      cohortName: cohortName ?? this.cohortName,
      cohortSubject: cohortSubject ?? this.cohortSubject,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cohortId,
        studentId,
        joinedAt,
        cohortName,
        cohortSubject,
        teacherName,
      ];

  @override
  String toString() {
    return 'CohortEnrollment{id: $id, cohort: $cohortName, joinedAt: $joinedAt}';
  }
}
