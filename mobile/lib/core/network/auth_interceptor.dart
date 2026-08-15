import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_events.dart';

/// Attaches the bearer access token to outgoing requests and transparently
/// refreshes it once on a 401, retrying the original request.
///
/// Concurrent 401s share a single in-flight refresh (single-flight) so we never
/// rotate the refresh token more than once at a time. If the refresh fails the
/// session is considered expired and an event is emitted.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.authEventBus,
    required this.baseUrl,
  }) : _refreshDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ));

  final TokenStorage tokenStorage;
  final AuthEventBus authEventBus;
  final String baseUrl;

  /// Bare Dio without this interceptor, used to call the refresh endpoint so we
  /// don't recurse into ourselves.
  final Dio _refreshDio;

  Future<String?>? _ongoingRefresh;

  /// Endpoints that must never carry a token nor trigger a refresh.
  static const _authPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/social',
    '/auth/refresh',
    '/auth/logout',
  };

  bool _isAuthPath(String path) => _authPaths.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthPath(options.path)) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final shouldAttemptRefresh =
        response?.statusCode == 401 &&
        !_isAuthPath(requestOptions.path) &&
        requestOptions.extra['retried'] != true;

    if (!shouldAttemptRefresh) {
      return handler.next(err);
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      authEventBus.notifySessionExpired();
      return handler.next(err);
    }

    try {
      requestOptions.extra['retried'] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final retried = await _refreshDio.fetch<dynamic>(requestOptions);
      return handler.resolve(retried);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Returns a fresh access token, or null when refresh is impossible.
  /// Shares a single in-flight refresh across concurrent callers.
  Future<String?> _refreshAccessToken() {
    return _ongoingRefresh ??= _performRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data;
      if (data == null) return null;

      final accessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      if (accessToken == null || newRefreshToken == null) return null;

      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } on DioException {
      await tokenStorage.clear();
      return null;
    }
  }
}
