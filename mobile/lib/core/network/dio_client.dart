import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_events.dart';
import 'auth_interceptor.dart';

/// The application-wide configured [Dio] instance for Riverpod: base URL, JSON content type,
/// timeouts, bearer-token attachment and transparent 401 refresh.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.networkTimeout,
      receiveTimeout: AppConfig.networkTimeout,
      sendTimeout: AppConfig.networkTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      authEventBus: ref.watch(authEventBusProvider),
      baseUrl: AppConfig.baseUrl,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return dio;
});

/// Static factory for creating custom [Dio] instances (used by GetIt dependency injection).
class DioClient {
  static Dio create({
    required String baseUrl,
    required FlutterSecureStorage storage,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
      SecureStorageAuthInterceptor(dio: dio, storage: storage),
      ErrorInterceptor(),
    ]);
    return dio;
  }
}

class SecureStorageAuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  late final Dio _refreshDio;

  SecureStorageAuthInterceptor({required this.dio, required this.storage}) {
    // Use a SEPARATE Dio for refresh calls to avoid QueuedInterceptor deadlock.
    _refreshDio = Dio(BaseOptions(
      baseUrl: dio.options.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ));
  }

  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: _accessKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  static final authFailureStream = StreamController<void>.broadcast();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshCall(err)) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with the new token using the bare Dio to avoid re-queuing.
          final opts = err.requestOptions;
          final newToken = await storage.read(key: _accessKey);
          if (newToken != null) {
            opts.headers['Authorization'] = 'Bearer $newToken';
          }
          final clone = await _refreshDio.fetch<dynamic>(opts);
          return handler.resolve(clone);
        }
        await storage.deleteAll();
        authFailureStream.add(null);
      } catch (_) {
        await storage.deleteAll();
        authFailureStream.add(null);
      }
    }
    handler.next(err);
  }

  bool _isRefreshCall(DioException err) =>
      err.requestOptions.path.contains('/auth/refresh');

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: _refreshKey);
    if (refreshToken == null) return false;

    try {
      final res = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (res.statusCode == 200) {
        await storage.write(key: _accessKey, value: res.data['accessToken']);
        await storage.write(key: _refreshKey, value: res.data['refreshToken']);
        return true;
      }
      return false;
    } on DioException {
      return false;
    }
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String? ?? err.message;
        err = DioException(
          requestOptions: err.requestOptions,
          response: response,
          type: err.type,
          error: err.error,
          message: message,
        );
      }
    }
    handler.next(err);
  }
}
