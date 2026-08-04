import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contrat commun à tous les use cases.
///
/// Un use case encapsule une intention métier unique. Il prend des [Params]
/// typés et retourne un `Either<Failure, Type>` : soit un échec explicite,
/// soit le résultat. Cela force la couche présentation à traiter les deux cas.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Pour les use cases sans paramètre.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
