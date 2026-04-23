import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../models/quiz/pending_quiz_submission.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../storage/isar_service.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

const refreshCacheTaskName = 'com.digikul.refreshCache';
const syncPendingTaskName = 'com.digikul.syncPending';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case refreshCacheTaskName:
          await _runRefreshCache();
        case syncPendingTaskName:
          await _runSyncTask();
        default:
          await _runSyncTask();
      }
      return true;
    } catch (e) {
      _logger.e('Background task "$taskName" failed: $e');
      return false;
    }
  });
}

Future<void> _runRefreshCache() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(StorageKeys.workerAuthToken);
  final cookie = prefs.getString(StorageKeys.workerSessionCookie);
  if ((token == null || token.isEmpty) && (cookie == null || cookie.isEmpty)) {
    return;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      },
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  try {
    await dio.get(ApiConstants.studentLectures);
    await dio.get(ApiConstants.studentMaterials);
    await dio.get(ApiConstants.attendance);
    await dio.get(ApiConstants.studentQuizzes);
  } catch (e) {
    _logger.w('Background cache refresh partially failed: $e');
  }
}

Future<void> _runSyncTask() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(StorageKeys.workerAuthToken);
  final cookie = prefs.getString(StorageKeys.workerSessionCookie);
  if ((token == null || token.isEmpty) && (cookie == null || cookie.isEmpty)) {
    return;
  }

  final isar = await IsarService.instance;

  final pending = await isar.pendingQuizSubmissions
      .filter()
      .isSyncedEqualTo(false)
      .syncAttemptsLessThan(5)
      .findAll();

  if (pending.isEmpty) return;

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
        'Content-Type': 'application/json',
      },
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  for (final submission in pending) {
    try {
      final answers =
          jsonDecode(submission.answersJson) as Map<String, dynamic>;

      await dio.post(
        ApiConstants.quizAttemptSubmit(submission.attemptId),
        data: {'answers': answers},
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
      _logger.w('Failed to sync submission ${submission.attemptId}: $e');
    }
  }
}
