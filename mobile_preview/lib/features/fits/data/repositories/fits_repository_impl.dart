import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fit_item.dart';
import '../../domain/repositories/fits_repository.dart';
import '../datasources/fits_local_datasource.dart';

class FitsRepositoryImpl implements FitsRepository {
  final FitsLocalDataSource local;
  FitsRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<FitItem>>> getFits({required FitKind kind}) async {
    try {
      final models = await local.getFits(kind);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> recordSwipe({
    required String targetId,
    required String targetType,
    required String direction,
    String? jobOfferId,
  }) async {
    try {
      final matched = await local.recordSwipe(
        targetId: targetId,
        targetType: targetType,
        direction: direction,
        jobOfferId: jobOfferId,
      );
      return Right(matched);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }
}

