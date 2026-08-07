import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Construit et configure le client HTTP Dio de l'application.
///
/// L'[AuthInterceptor] attache le JWT à chaque requête et gère le refresh
/// transparent sur 401 — l'utilisateur ne voit jamais une déconnexion due à
/// l'expiration de l'access token (15 min).
class DioClient {
  static Dio create({required String baseUrl, required FlutterSecureStorage storage}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
    dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage));
    return dio;
  }
}

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthInterceptor({required this.dio, required this.storage});

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: _accessKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 → tenter un refresh puis rejouer la requête une seule fois
    if (err.response?.statusCode == 401 && !_isRefreshCall(err)) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final clone = await _retry(err.requestOptions);
          return handler.resolve(clone);
        }
      } catch (_) {
        // refresh échoué → on laisse remonter le 401 (déconnexion gérée plus haut)
      }
    }
    handler.next(err);
  }

  bool _isRefreshCall(DioException err) =>
      err.requestOptions.path.contains('/auth/refresh');

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: _refreshKey);
    if (refreshToken == null) return false;

    final res = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    if (res.statusCode == 200) {
      await storage.write(key: _accessKey, value: res.data['accessToken']);
      await storage.write(key: _refreshKey, value: res.data['refreshToken']);
      return true;
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    return dio.fetch(options);
  }
}
