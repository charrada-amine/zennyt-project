import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recruiter_job_offer.dart';
import '../../domain/entities/recruiter_test.dart';
import '../../domain/repositories/careers_repository.dart';
import '../datasources/careers_local_datasource.dart';

class CareersRepositoryImpl implements CareersRepository {
  final CareersLocalDataSource local;
  CareersRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<RecruiterTest>>> getTests() async {
    try {
      return Right(await local.getTests());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<RecruiterJobOffer>>> getJobOffers() async {
    try {
      return Right(await local.getJobOffers());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
