import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_events.dart';
import 'auth_interceptor.dart';

/// The application-wide configured [Dio] instance: base URL, JSON content type,
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
      // Let our interceptor/repository decide how to map non-2xx responses.
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
