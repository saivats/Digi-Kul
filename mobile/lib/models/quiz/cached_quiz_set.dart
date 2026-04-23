class CachedQuizSet {
  CachedQuizSet({
    required this.serverId,
    required this.title,
    required this.description,
    required this.cohortId,
    required this.questionCount,
    this.timeLimitMinutes,
    this.maxAttempts,
    this.passingScore,
    required this.showCorrectAnswers,
    this.availableFrom,
    this.availableUntil,
    this.cachedAt,
  });

  final String serverId;
  final String title;
  final String description;
  final String cohortId;
  final int questionCount;
  final int? timeLimitMinutes;
  final int? maxAttempts;
  final double? passingScore;
  final bool showCorrectAnswers;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? cachedAt;
}
