import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response> login({
    required String email,
    required String password,
    String? institutionId,
  }) {
    return _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'user_type': 'student',
        if (institutionId != null) 'institution_id': institutionId,
      },
    );
  }

  Future<Response> registerStudent({
    required Map<String, dynamic> studentData,
  }) {
    return _dio.post(ApiConstants.registerStudent, data: studentData);
  }

  Future<Response> validateSession() {
    return _dio.get(ApiConstants.validateSession);
  }

  Future<Response> logout() {
    return _dio.post(ApiConstants.logout);
  }

  Future<Response> getInstitutions() {
    return _dio.get(ApiConstants.institutions);
  }

  Future<Response> getCohorts() {
    return _dio.get(ApiConstants.studentCohorts);
  }

  Future<Response> getLectures() {
    return _dio.get(ApiConstants.studentLectures);
  }

  Future<Response> getUpcomingLectures() {
    return _dio.get(ApiConstants.upcomingLectures);
  }

  Future<Response> getMaterials() {
    return _dio.get(ApiConstants.studentMaterials);
  }

  Future<Response> getQuizSets() {
    return _dio.get(ApiConstants.studentQuizzes);
  }

  Future<Response> startQuizAttempt(String quizSetId) {
    return _dio.post(
      ApiConstants.quizAttempts,
      data: {'quiz_set_id': quizSetId},
    );
  }

  Future<Response> submitQuizResponse({
    required String attemptId,
    required String questionId,
    required String response,
  }) {
    return _dio.post(
      ApiConstants.quizResponses,
      data: {
        'attempt_id': attemptId,
        'question_id': questionId,
        'response': response,
      },
    );
  }

  Future<Response> getQuizQuestions(String quizSetId) {
    return _dio.get(ApiConstants.quizQuestions(quizSetId));
  }

  Future<Response> submitQuizAttempt({
    required String attemptId,
    required Map<String, String> answers,
  }) {
    return _dio.post(
      ApiConstants.quizAttemptSubmit(attemptId),
      data: {'answers': answers},
    );
  }

  Future<Response> getQuizResult(String attemptId) {
    return _dio.get(ApiConstants.quizResult(attemptId));
  }

  Future<Response> getAttendance() {
    return _dio.get(ApiConstants.attendance);
  }

  Future<Response> registerFcmToken(String token) {
    return _dio.post(ApiConstants.fcmToken, data: {'token': token});
  }

  Future<Response> downloadMaterial(String url, String savePath, {
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
  }
}
