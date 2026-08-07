import 'package:dio/dio.dart';

/// Abstraction de l'état de connectivité, utilisée par les Repository pour
/// décider entre source distante et cache local (offline-first).
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implémentation simple par ping. En production, brancher `connectivity_plus`.
class NetworkInfoImpl implements NetworkInfo {
  final Dio dio;
  NetworkInfoImpl(this.dio);

  @override
  Future<bool> get isConnected async {
    try {
      await dio.get('/actuator/health',
          options: Options(receiveTimeout: const Duration(seconds: 3)));
      return true;
    } catch (_) {
      return false;
    }
  }
}
