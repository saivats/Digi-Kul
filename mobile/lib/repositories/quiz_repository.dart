import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../core/storage/isar_service.dart';
import '../models/quiz/pending_quiz_submission.dart';
import '../models/quiz/quiz_attempt_dto.dart';
import '../models/quiz/quiz_question_dto.dart';
import '../models/quiz/quiz_result_dto.dart';
import '../models/quiz/quiz_set_dto.dart';
import '../core/storage/preferences.dart';
import '../providers/core_providers.dart';

part 'quiz_repository.g.dart';

@riverpod
QuizRepository quizRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuizRepository(apiClient);
}

class QuizRepository {
  QuizRepository(this._apiClient);

  final ApiClient _apiClient;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<List<QuizSetDto>> getQuizSets() async {
    try {
      final response = await _apiClient.getQuizSets();
      final data = response.data;

      if (data is Map<String, dynamic> && data['quizzes'] is List) {
        final quizzes = (data['quizzes'] as List)
            .map((e) => QuizSetDto.fromJson(_normalizeQuizSet(e)))
            .toList();

        return _mergeWithPendingAttempts(quizzes);
      }

      if (data is Map<String, dynamic> && data['quiz_sets'] is List) {
        final quizzes = (data['quiz_sets'] as List)
            .map((e) => QuizSetDto.fromJson(_normalizeQuizSet(e)))
            .toList();

        return _mergeWithPendingAttempts(quizzes);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<QuizQuestionDto>> getQuestions(String quizSetId) async {
    final response = await _apiClient.getQuizQuestions(quizSetId);
    final data = response.data;

    if (data is Map<String, dynamic> && data['questions'] is List) {
      return (data['questions'] as List)
          .map(
              (e) => QuizQuestionDto.fromJson(_normalizeQuestion(e, quizSetId)))
          .toList();
    }

    return [];
  }

  Future<List<QuizQuestionDto>> getQuestionsForAttempt({
    required String attemptId,
    required String quizSetId,
  }) async {
    final response = await _apiClient.getQuizQuestionsForAttempt(attemptId);
    final data = response.data;

    if (data is Map<String, dynamic> && data['questions'] is List) {
      return (data['questions'] as List)
          .map(
              (e) => QuizQuestionDto.fromJson(_normalizeQuestion(e, quizSetId)))
          .toList();
    }

    return [];
  }

  Future<QuizAttemptDto> startAttempt(String quizSetId) async {
    final response = await _apiClient.startQuizAttempt(quizSetId);
    final data = response.data as Map<String, dynamic>;
    final attempt = data['attempt'] as Map<String, dynamic>?;
    final attemptId =
        data['attempt_id'] as String? ?? attempt?['id'] as String?;

    if (attemptId == null || attemptId.isEmpty) {
      throw StateError('Quiz attempt response did not include an attempt id.');
    }

    return QuizAttemptDto(
      id: attemptId,
      quizSetId: attempt?['quiz_set_id'] as String? ?? quizSetId,
      studentId: attempt?['student_id'] as String? ??
          PreferencesService.studentId ??
          '',
      startedAt: DateTime.tryParse(attempt?['started_at'] as String? ?? '') ??
          DateTime.now(),
      submittedAt: DateTime.tryParse(attempt?['submitted_at'] as String? ?? ''),
      status: attempt?['status'] as String? ?? 'in_progress',
    );
  }

  Future<QuizResultDto?> submitAttempt({
    required String attemptId,
    required Map<String, String> answers,
    required String quizSetId,
  }) async {
    try {
      final response = await _apiClient.submitQuizAttempt(
        attemptId: attemptId,
        answers: answers,
      );

      final data = response.data as Map<String, dynamic>;
      return QuizResultDto.fromJson(
          _normalizeResult(data, attemptId, quizSetId));
    } catch (e) {
      _logger.w('Online submit failed, queueing for background sync: $e');
      await _queueForSync(
          attemptId: attemptId, answers: answers, quizSetId: quizSetId);
      return null;
    }
  }

  Future<QuizResultDto> getResult(String attemptId) async {
    final response = await _apiClient.getQuizResult(attemptId);
    return QuizResultDto.fromJson(
      _normalizeResult(response.data as Map<String, dynamic>, attemptId, ''),
    );
  }

  Future<void> saveAnswerLocally({
    required String attemptId,
    required String quizSetId,
    required Map<String, String> answers,
    DateTime? startedAt,
  }) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      final existing =
          await isar.pendingQuizSubmissions.getByAttemptId(attemptId);
      final submission = existing ?? PendingQuizSubmission();
      submission
        ..attemptId = attemptId
        ..quizSetId = quizSetId
        ..studentId = PreferencesService.studentId ?? ''
        ..answersJson = jsonEncode(answers)
        ..startedAt = startedAt ?? submission.startedAtOrNow
        ..attemptedAt = DateTime.now()
        ..isSynced = false;

      if (existing == null) {
        submission.syncAttempts = 0;
      }

      await isar.pendingQuizSubmissions.putByAttemptId(submission);
    });
  }

  Future<void> _queueForSync({
    required String attemptId,
    required Map<String, String> answers,
    required String quizSetId,
  }) async {
    final isar = await IsarService.instance;
    final submission = PendingQuizSubmission()
      ..attemptId = attemptId
      ..quizSetId = quizSetId
      ..studentId = ''
      ..answersJson = jsonEncode(answers)
      ..startedAt = DateTime.now()
      ..attemptedAt = DateTime.now()
      ..isSynced = false
      ..syncAttempts = 0;

    await isar.writeTxn(() async {
      await isar.pendingQuizSubmissions.putByAttemptId(submission);
    });
  }

  Future<int> pendingSubmissionCount() async {
    final isar = await IsarService.instance;
    return isar.pendingQuizSubmissions.filter().isSyncedEqualTo(false).count();
  }

  Future<void> syncPendingSubmissions() async {
    final isar = await IsarService.instance;
    final pending = await isar.pendingQuizSubmissions
        .filter()
        .isSyncedEqualTo(false)
        .syncAttemptsLessThan(5)
        .findAll();

    for (final submission in pending) {
      try {
        final answers =
            jsonDecode(submission.answersJson) as Map<String, dynamic>;
        final stringAnswers = answers.map((k, v) => MapEntry(k, v.toString()));

        await _apiClient.submitQuizAttempt(
          attemptId: submission.attemptId,
          answers: stringAnswers,
        );

        await isar.writeTxn(() async {
          submission.isSynced = true;
          await isar.pendingQuizSubmissions.put(submission);
        });
      } catch (e) {
        await isar.writeTxn(() async {
          submission.syncAttempts++;
          submission.syncError = e.toString();
          await isar.pendingQuizSubmissions.put(submission);
        });
        _logger.w('Failed to sync attempt ${submission.attemptId}: $e');
      }
    }
  }

  Future<List<QuizSetDto>> _mergeWithPendingAttempts(
      List<QuizSetDto> quizzes) async {
    final isar = await IsarService.instance;
    final pending = await isar.pendingQuizSubmissions
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    final pendingQuizIds =
        pending.map((submission) => submission.quizSetId).toSet();

    return quizzes
        .map(
          (quiz) => pendingQuizIds.contains(quiz.id)
              ? quiz.copyWith(isInProgress: true)
              : quiz,
        )
        .toList();
  }

  Map<String, dynamic> _normalizeQuizSet(Object? value) {
    final json = Map<String, dynamic>.from(value as Map);
    final timeLimit = json['time_limit_seconds'] ?? json['time_limit'];
    final timeLimitSeconds = timeLimit is int
        ? (json.containsKey('time_limit_seconds') ? timeLimit : timeLimit * 60)
        : null;

    return {
      ...json,
      'description': json['description'] ?? '',
      'cohort_id': json['cohort_id'] ?? '',
      'question_count': json['question_count'] ?? 0,
      'time_limit_seconds': timeLimitSeconds,
      'show_correct_answers': json['show_correct_answers'] ?? true,
      'available_from': json['available_from'] ??
          json['starts_at'] ??
          json['created_at'] ??
          '1970-01-01T00:00:00.000Z',
      'available_until': json['available_until'] ?? json['ends_at'],
      'status': json['status'] ??
          (json['is_active'] == false ? 'expired' : 'available'),
    };
  }

  Map<String, dynamic> _normalizeQuestion(Object? value, String quizSetId) {
    final json = Map<String, dynamic>.from(value as Map);
    return {
      ...json,
      'quiz_set_id': json['quiz_set_id'] ?? quizSetId,
      'question': json['question'] ?? json['question_text'] ?? '',
      'question_type': json['question_type'] ?? 'mcq',
      'options': json['options'] ?? <String>[],
      'order_index': json['order_index'] ?? json['question_order'] ?? 0,
    };
  }

  Map<String, dynamic> _normalizeResult(
    Map<String, dynamic> data,
    String attemptId,
    String quizSetId,
  ) {
    final result = data['result'] is Map<String, dynamic>
        ? data['result'] as Map<String, dynamic>
        : data;

    return {
      ...result,
      'attempt_id': result['attempt_id'] ?? result['id'] ?? attemptId,
      'quiz_set_id': result['quiz_set_id'] ?? quizSetId,
      'total_questions': result['total_questions'] ?? 0,
      'correct_answers':
          result['correct_answers'] ?? result['correct_count'] ?? 0,
      'score_percentage': (result['score_percentage'] ??
              result['percentage'] ??
              result['score'] ??
              0)
          .toDouble(),
      'time_taken_seconds': result['time_taken_seconds'] ??
          result['time_taken'] ??
          result['time_spent_seconds'],
      'review': result['review'] ??
          result['question_review'] ??
          <Map<String, dynamic>>[],
    };
  }
}

extension on PendingQuizSubmission {
  DateTime get startedAtOrNow {
    try {
      return startedAt;
    } catch (_) {
      return DateTime.now();
    }
  }
}
