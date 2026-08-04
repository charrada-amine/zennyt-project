import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/job.dart';
import '../entities/job_filter.dart';
import '../repositories/job_repository.dart';

/// Use case : récupérer une page d'offres selon des critères.
class GetJobs implements UseCase<List<Job>, GetJobsParams> {
  final JobRepository repository;
  GetJobs(this.repository);

  @override
  Future<Either<Failure, List<Job>>> call(GetJobsParams params) {
    return repository.getJobs(
      filter: params.filter, page: params.page, size: params.size);
  }
}

class GetJobsParams extends Equatable {
  final JobFilter filter;
  final int page;
  final int size;
  const GetJobsParams({required this.filter, this.page = 0, this.size = 20});

  @override
  List<Object?> get props => [filter, page, size];
}
