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
            .map((e) => QuizSetDto.fromJson(e as Map<String, dynamic>))
            .toList();

        return quizzes;
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
          .map((e) => QuizQuestionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<QuizAttemptDto> startAttempt(String quizSetId) async {
    final response = await _apiClient.startQuizAttempt(quizSetId);
    return QuizAttemptDto.fromJson(response.data as Map<String, dynamic>);
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

      return QuizResultDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.w('Online submit failed, queueing for background sync: $e');
      await _queueForSync(
          attemptId: attemptId, answers: answers, quizSetId: quizSetId);
      return null;
    }
  }

  Future<QuizResultDto> getResult(String attemptId) async {
    final response = await _apiClient.getQuizResult(attemptId);
    return QuizResultDto.fromJson(response.data as Map<String, dynamic>);
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
      await isar.pendingQuizSubmissions.put(submission);
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
}
