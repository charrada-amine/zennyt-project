/// Exceptions techniques levées par les DataSources (couche data uniquement).
///
/// Elles sont converties en [Failure] par les Repository — elles ne remontent
/// jamais jusqu'au domaine ou à la présentation.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);
}
