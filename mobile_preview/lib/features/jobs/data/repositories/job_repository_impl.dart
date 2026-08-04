import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_filter.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_local_datasource.dart';
import '../datasources/job_remote_datasource.dart';

/// Implémentation du port [JobRepository].
///
/// Porte la stratégie offline-first : si en ligne, on lit le réseau et on met
/// le cache à jour ; si hors ligne, on sert le cache. La conversion
/// exception → Failure se fait ici, isolant le domaine des détails techniques.
class JobRepositoryImpl implements JobRepository {
  final JobRemoteDataSource remote;
  final JobLocalDataSource local;
  final NetworkInfo networkInfo;

  JobRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Job>>> getJobs({
    required JobFilter filter,
    required int page,
    required int size,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remote.getJobs(filter: filter, page: page, size: size);
        if (page == 0) {
          await local.cacheJobs(models); // on ne cache que la première page
        }
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      }
    } else {
      // Hors ligne → repli sur le cache
      try {
        final cached = await local.getCachedJobs();
        return Right(cached.map((m) => m.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Job>> getJobDetail(String jobId) async {
    try {
      final model = await remote.getJobDetail(jobId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }
}
