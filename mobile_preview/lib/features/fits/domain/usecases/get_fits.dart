import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/fit_item.dart';
import '../repositories/fits_repository.dart';

/// Use case : charger le deck "Fits" selon le type (offres / pros).
class GetFits implements UseCase<List<FitItem>, GetFitsParams> {
  final FitsRepository repository;
  GetFits(this.repository);

  @override
  Future<Either<Failure, List<FitItem>>> call(GetFitsParams params) {
    return repository.getFits(kind: params.kind);
  }
}

class GetFitsParams extends Equatable {
  final FitKind kind;
  const GetFitsParams({required this.kind});

  @override
  List<Object?> get props => [kind];
}
