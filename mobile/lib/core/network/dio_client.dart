import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../errors/error_handler.dart';
import '../storage/secure_storage.dart';

class DioClient {
  DioClient._();


  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      _LoggingInterceptor(),
    ]);

    return dio;
  }

  static void reset() {
    _dio?.close();
    _dio = null;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final cookie = await SecureStorageService.getSessionCookie();
    if (cookie != null && cookie.isNotEmpty) {
      options.headers['Cookie'] = cookie;
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      await SecureStorageService.saveSessionCookie(setCookie.first);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshed = await _attemptTokenRefresh(refreshToken);
        if (refreshed) {
          final retryResponse = await _retryRequest(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      }
      await SecureStorageService.clearAuth();
    }
    handler.next(err);
  }

  Future<bool> _attemptTokenRefresh(String refreshToken) async {
    try {
      final refreshDio = Dio(
        BaseOptions(baseUrl: ApiConstants.baseUrl),
      );
      final response = await refreshDio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['access_token'] as String?;
        if (newToken != null) {
          await SecureStorageService.saveAuthToken(newToken);
          final newRefresh = data['refresh_token'] as String?;
          if (newRefresh != null) {
            await SecureStorageService.saveRefreshToken(newRefresh);
          }
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    final token = await SecureStorageService.getAuthToken();
    options.headers['Authorization'] = 'Bearer $token';
    return DioClient.instance.fetch(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = ErrorHandler.handleDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }
}

class _LoggingInterceptor extends Interceptor {
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      _logger.d('→ ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      _logger.e('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
      return true;
    }());
    handler.next(err);
  }
}
