import 'package:dio/dio.dart';

/// A single field-level validation error returned by the backend.
class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;

  factory FieldError.fromJson(Map<String, dynamic> json) => FieldError(
    field: (json['field'] ?? '').toString(),
    message: (json['message'] ?? '').toString(),
  );
}

/// Base type for every error surfaced by the network layer.
///
/// The backend uses a unified error body:
/// `{ timestamp, status, error, message, path, fieldErrors[] }`.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Maps a raw [DioException] into a typed [ApiException].
  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ConnectionException();
      case DioExceptionType.cancel:
        return const ConnectionException(message: 'Request cancelled');
      case DioExceptionType.badCertificate:
        return const ConnectionException(message: 'Bad server certificate');
      case DioExceptionType.unknown:
        return ConnectionException(message: error.message ?? 'Network error');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;

    String message = 'Unexpected error';
    List<FieldError> fieldErrors = const [];

    if (data is Map<String, dynamic>) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
      }
      final rawFieldErrors = data['fieldErrors'];
      if (rawFieldErrors is List) {
        fieldErrors = rawFieldErrors
            .whereType<Map<String, dynamic>>()
            .map(FieldError.fromJson)
            .toList(growable: false);
      }
    }

    switch (status) {
      case 400:
        return BadRequestException(message: message, fieldErrors: fieldErrors);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ConflictException(message: message);
      default:
        return ServerException(message: message, statusCode: status);
    }
  }
}

class BadRequestException extends ApiException {
  const BadRequestException({
    String message = 'Invalid request',
    this.fieldErrors = const [],
  }) : super(message, statusCode: 400);

  final List<FieldError> fieldErrors;

  @override
  String toString() {
    if (fieldErrors.isEmpty) return super.toString();
    final errors = fieldErrors.map((e) => '${e.field}: ${e.message}').join(', ');
    return '${super.toString()} [$errors]';
  }
}

/// 401 — missing/invalid credentials or token.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({String message = 'Unauthorized'})
    : super(message, statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ApiException {
  const ForbiddenException({String message = 'Forbidden'})
    : super(message, statusCode: 403);
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException({String message = 'Not found'})
    : super(message, statusCode: 404);
}

/// 409 — conflict, e.g. duplicate email on register.
class ConflictException extends ApiException {
  const ConflictException({String message = 'Conflict'})
    : super(message, statusCode: 409);
}

/// 5xx or otherwise unexpected server response.
class ServerException extends ApiException {
  const ServerException({String message = 'Server error', int? statusCode})
    : super(message, statusCode: statusCode);
}

/// Transport-level failure (no/lost connectivity, timeout).
class ConnectionException extends ApiException {
  const ConnectionException({String message = 'Connection failed'})
    : super(message);
}
