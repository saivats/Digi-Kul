import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'poll.g.dart';

/// Poll model representing interactive questions during lectures
@JsonSerializable()
class Poll extends Equatable {

  const Poll({
    required this.id,
    this.lectureId,
    required this.teacherId,
    required this.question,
    required this.options,
    required this.createdAt,
    this.isActive = true,
    this.teacherName,
    this.lectureTitle,
    this.totalVotes,
    this.userResponse,
    this.hasVoted,
  });

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
  final String id;
  @JsonKey(name: 'lecture_id')
  final String? lectureId;
  @JsonKey(name: 'teacher_id')
  final String teacherId;
  final String question;
  final List<String> options;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'lecture_title')
  final String? lectureTitle;
  @JsonKey(name: 'total_votes')
  final int? totalVotes;
  @JsonKey(name: 'user_response')
  final String? userResponse;
  @JsonKey(name: 'has_voted')
  final bool? hasVoted;

  Map<String, dynamic> toJson() => _$PollToJson(this);

  Poll copyWith({
    String? id,
    String? lectureId,
    String? teacherId,
    String? question,
    List<String>? options,
    DateTime? createdAt,
    bool? isActive,
    String? teacherName,
    String? lectureTitle,
    int? totalVotes,
    String? userResponse,
    bool? hasVoted,
  }) {
    return Poll(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      teacherId: teacherId ?? this.teacherId,
      question: question ?? this.question,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      teacherName: teacherName ?? this.teacherName,
      lectureTitle: lectureTitle ?? this.lectureTitle,
      totalVotes: totalVotes ?? this.totalVotes,
      userResponse: userResponse ?? this.userResponse,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }

  /// Check if the user has voted on this poll
  bool get isVoted => hasVoted ?? false || userResponse != null;

  /// Check if this is a general poll (not associated with a specific lecture)
  bool get isGeneralPoll => lectureId == null;

  /// Get formatted total votes
  String get formattedTotalVotes {
    if (totalVotes == null) return '0 votes';
    if (totalVotes == 1) return '1 vote';
    return '$totalVotes votes';
  }

  @override
  List<Object?> get props => [
        id,
        lectureId,
        teacherId,
        question,
        options,
        createdAt,
        isActive,
        teacherName,
        lectureTitle,
        totalVotes,
        userResponse,
        hasVoted,
      ];

  @override
  String toString() {
    return 'Poll{id: $id, question: $question, options: ${options.length}, votes: $totalVotes}';
  }
}

/// Poll response model
@JsonSerializable()
class PollResponse extends Equatable {

  const PollResponse({
    required this.id,
    required this.studentId,
    required this.pollId,
    required this.response,
    required this.submittedAt,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) =>
      _$PollResponseFromJson(json);
  final String id;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'poll_id')
  final String pollId;
  final String response;
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;

  Map<String, dynamic> toJson() => _$PollResponseToJson(this);

  @override
  List<Object?> get props => [id, studentId, pollId, response, submittedAt];
}

/// Poll results with vote counts and percentages
@JsonSerializable()
class PollResults extends Equatable {

  const PollResults({
    required this.pollId,
    required this.question,
    required this.totalVotes,
    required this.results,
    required this.createdAt,
  });

  factory PollResults.fromJson(Map<String, dynamic> json) =>
      _$PollResultsFromJson(json);
  @JsonKey(name: 'poll_id')
  final String pollId;
  final String question;
  @JsonKey(name: 'total_votes')
  final int totalVotes;
  final List<PollOptionResult> results;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$PollResultsToJson(this);

  /// Get the winning option (most votes)
  PollOptionResult? get winningOption {
    if (results.isEmpty) return null;
    
    var winner = results.first;
    for (final result in results) {
      if (result.votes > winner.votes) {
        winner = result;
      }
    }
    return winner;
  }

  /// Get formatted total votes
  String get formattedTotalVotes {
    if (totalVotes == 1) return '1 vote';
    return '$totalVotes votes';
  }

  @override
  List<Object?> get props => [pollId, question, totalVotes, results, createdAt];

  @override
  String toString() {
    return 'PollResults{pollId: $pollId, totalVotes: $totalVotes, options: ${results.length}}';
  }
}

/// Individual poll option result
@JsonSerializable()
class PollOptionResult extends Equatable {

  const PollOptionResult({
    required this.option,
    required this.votes,
    required this.percentage,
  });

  factory PollOptionResult.fromJson(Map<String, dynamic> json) =>
      _$PollOptionResultFromJson(json);
  final String option;
  final int votes;
  final double percentage;

  Map<String, dynamic> toJson() => _$PollOptionResultToJson(this);

  /// Get formatted percentage
  String get formattedPercentage {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Get formatted votes
  String get formattedVotes {
    if (votes == 1) return '1 vote';
    return '$votes votes';
  }

  @override
  List<Object?> get props => [option, votes, percentage];

  @override
  String toString() {
    return 'PollOptionResult{option: $option, votes: $votes, percentage: $percentage%}';
  }
}

/// Request to vote on a poll
@JsonSerializable()
class PollVoteRequest extends Equatable {

  const PollVoteRequest({
    required this.response,
  });

  factory PollVoteRequest.fromJson(Map<String, dynamic> json) =>
      _$PollVoteRequestFromJson(json);
  final String response;

  Map<String, dynamic> toJson() => _$PollVoteRequestToJson(this);

  @override
  List<Object?> get props => [response];
}

/// Poll summary for list views
@JsonSerializable()
class PollSummary extends Equatable {

  const PollSummary({
    required this.id,
    required this.question,
    required this.optionCount,
    this.lectureTitle,
    this.teacherName,
    required this.createdAt,
    this.hasVoted = false,
    this.totalVotes = 0,
  });

  factory PollSummary.fromJson(Map<String, dynamic> json) =>
      _$PollSummaryFromJson(json);

  factory PollSummary.fromPoll(Poll poll) {
    return PollSummary(
      id: poll.id,
      question: poll.question,
      optionCount: poll.options.length,
      lectureTitle: poll.lectureTitle,
      teacherName: poll.teacherName,
      createdAt: poll.createdAt,
      hasVoted: poll.isVoted,
      totalVotes: poll.totalVotes ?? 0,
    );
  }
  final String id;
  final String question;
  final int optionCount;
  final String? lectureTitle;
  final String? teacherName;
  final DateTime createdAt;
  final bool hasVoted;
  final int totalVotes;

  Map<String, dynamic> toJson() => _$PollSummaryToJson(this);

  /// Get truncated question for display
  String get truncatedQuestion {
    if (question.length <= 100) return question;
    return '${question.substring(0, 97)}...';
  }

  @override
  List<Object?> get props => [
        id,
        question,
        optionCount,
        lectureTitle,
        teacherName,
        createdAt,
        hasVoted,
        totalVotes,
      ];
}
