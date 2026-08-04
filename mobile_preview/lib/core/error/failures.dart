import 'package:equatable/equatable.dart';

/// Échecs métier remontés jusqu'au BLoC via `Either<Failure, T>`.
///
/// Contrairement aux exceptions (couche data), les Failures sont des valeurs
/// que la couche présentation traite explicitement — pas de try/catch qui traîne.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Erreur côté serveur (4xx/5xx).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Perte de connexion / timeout réseau.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet']);
}

/// Échec de lecture/écriture du cache local.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de cache local']);
}

/// Authentification invalide ou expirée (401).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expirée']);
}
