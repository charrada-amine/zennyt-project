import 'package:dio/dio.dart';

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;
  ServerException(this.message, {this.statusCode, this.fieldErrors});
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);
}

ServerException handleDioException(DioException e) {
  final response = e.response;
  final data = response?.data as Map<String, dynamic>?;
  final message = data?['message'] as String? ?? e.message ?? 'Erreur serveur';
  Map<String, String>? fieldErrors;
  final fieldErrorsList = data?['fieldErrors'] as List<dynamic>?;
  if (fieldErrorsList != null && fieldErrorsList.isNotEmpty) {
    fieldErrors = {};
    for (final f in fieldErrorsList) {
      if (f is Map<String, dynamic>) {
        final field = f['field'] as String?;
        final msg = f['message'] as String?;
        if (field != null && msg != null) {
          fieldErrors[field] = msg;
        }
      }
    }
    if (fieldErrors.isEmpty) fieldErrors = null;
  }
  return ServerException(message, statusCode: response?.statusCode, fieldErrors: fieldErrors);
}
