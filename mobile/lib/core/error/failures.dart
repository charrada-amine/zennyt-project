import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de cache local']);
}

class AuthFailure extends Failure {
  const AuthFailure(
      [super.message = 'Session expirée, veuillez vous reconnecter']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Action non autorisée']);
}

class NotFoundFailure extends Failure {
  final String? resource;
  const NotFoundFailure(
      [super.message = 'Ressource introuvable', this.resource]);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflit: la ressource existe déjà']);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure(
      [super.message = 'Données invalides', this.fieldErrors]);
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure(
      [super.message = 'Trop de requêtes, réessayez plus tard']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class DataParsingFailure extends Failure {
  const DataParsingFailure(
      [super.message = 'Erreur de formatage des données reçues']);
}

Failure mapStatusCodeToFailure(int? statusCode, String message,
    {Map<String, String>? fieldErrors}) {
  switch (statusCode) {
    case 401:
      return AuthFailure(message);
    case 403:
      return ForbiddenFailure(message);
    case 404:
      return NotFoundFailure(message);
    case 409:
      return ConflictFailure(message);
    case 422:
      return ValidationFailure(message, fieldErrors);
    case 429:
      return TooManyRequestsFailure(message);
    case 500:
      return ServerFailure(message, statusCode: statusCode);
    default:
      return ServerFailure(message, statusCode: statusCode);
  }
}
