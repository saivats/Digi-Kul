class Poll {

  const Poll({
    required this.id,
    this.lectureId,
    required this.teacherId,
    required this.question,
    required this.options,
    required this.createdAt,
    this.isActive = true,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? '',
      lectureId: json['lecture_id'],
      teacherId: json['teacher_id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String? lectureId;
  final String teacherId;
  final String question;
  final List<String> options;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lecture_id': lectureId,
      'teacher_id': teacherId,
      'question': question,
      'options': options,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Poll copyWith({
    String? id,
    String? lectureId,
    String? teacherId,
    String? question,
    List<String>? options,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Poll(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      teacherId: teacherId ?? this.teacherId,
      question: question ?? this.question,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poll && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Poll{id: $id, question: $question, options: $options}';
  }
}

class PollResults {

  const PollResults({
    required this.pollId,
    required this.question,
    required this.totalVotes,
    required this.results,
    required this.createdAt,
  });

  factory PollResults.fromJson(Map<String, dynamic> json) {
    return PollResults(
      pollId: json['poll_id'] ?? '',
      question: json['question'] ?? '',
      totalVotes: json['total_votes'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((result) => PollOptionResult.fromJson(result))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
  final String pollId;
  final String question;
  final int totalVotes;
  final List<PollOptionResult> results;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'poll_id': pollId,
      'question': question,
      'total_votes': totalVotes,
      'results': results.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PollResults{pollId: $pollId, question: $question, totalVotes: $totalVotes, results: $results}';
  }
}

class PollOptionResult {

  const PollOptionResult({
    required this.option,
    required this.votes,
    required this.percentage,
  });

  factory PollOptionResult.fromJson(Map<String, dynamic> json) {
    return PollOptionResult(
      option: json['option'] ?? '',
      votes: json['votes'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
  final String option;
  final int votes;
  final double percentage;

  Map<String, dynamic> toJson() {
    return {
      'option': option,
      'votes': votes,
      'percentage': percentage,
    };
  }

  @override
  String toString() {
    return 'PollOptionResult{option: $option, votes: $votes, percentage: $percentage}';
  }
}