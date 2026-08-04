import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recruiter_test.dart';
import '../repositories/careers_repository.dart';

class GetMyTests implements UseCase<List<RecruiterTest>, NoParams> {
  final CareersRepository repository;
  GetMyTests(this.repository);

  @override
  Future<Either<Failure, List<RecruiterTest>>> call(NoParams params) =>
      repository.getTests();
}
