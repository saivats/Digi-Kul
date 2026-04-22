import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';

class ApiResponse {
  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  final bool success;
  final dynamic data;
  final String? error;

  factory ApiResponse.fromResponse(Response response) {
    final json = response.data as Map<String, dynamic>;
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'],
      error: json['error'] as String?,
    );
  }

  void ensureSuccess() {
    if (!success) {
      throw ServerException(message: error ?? 'Request failed');
    }
  }

  List<T> parseList<T>(T Function(Map<String, dynamic>) fromJson) {
    ensureSuccess();
    if (data == null) return [];
    return (data as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> parseObject() {
    ensureSuccess();
    return data as Map<String, dynamic>;
  }

  T parseSingle<T>(T Function(Map<String, dynamic>) fromJson) {
    ensureSuccess();
    return fromJson(data as Map<String, dynamic>);
  }
}
