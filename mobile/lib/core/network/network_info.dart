import 'package:dio/dio.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Dio dio;
  NetworkInfoImpl(this.dio);

  Future<bool>? _pendingCheck;
  DateTime? _lastCheck;
  bool? _lastResult;

  @override
  Future<bool> get isConnected async {
    if (_pendingCheck != null) return _pendingCheck!;

    if (_lastCheck != null && DateTime.now().difference(_lastCheck!) < const Duration(seconds: 3)) {
      return _lastResult ?? false;
    }

    _pendingCheck = _doCheck();
    final result = await _pendingCheck!;
    _pendingCheck = null;
    return result;
  }

  Future<bool> _doCheck() async {
    try {
      final baseUri = Uri.parse(dio.options.baseUrl);
      final healthUri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '/actuator/health',
      ).toString();

      await dio.get(
        healthUri,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _lastResult = true;
      _lastCheck = DateTime.now();
      return true;
    } catch (e) {
      _lastResult = false;
      _lastCheck = DateTime.now();
      return false;
    }
  }
}
