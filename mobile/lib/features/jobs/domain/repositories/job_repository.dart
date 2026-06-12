import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/job.dart';
import '../entities/job_filter.dart';

/// Port du domaine : contrat que la couche data doit implémenter.
///
/// Le domaine dépend de cette abstraction, jamais de Dio ou Hive.
abstract class JobRepository {
  Future<Either<Failure, List<Job>>> getJobs({
    required JobFilter filter,
    required int page,
    required int size,
  });

  Future<Either<Failure, Job>> getJobDetail(String jobId);
}
