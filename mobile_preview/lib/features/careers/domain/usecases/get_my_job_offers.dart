import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recruiter_job_offer.dart';
import '../repositories/careers_repository.dart';

class GetMyJobOffers implements UseCase<List<RecruiterJobOffer>, NoParams> {
  final CareersRepository repository;
  GetMyJobOffers(this.repository);

  @override
  Future<Either<Failure, List<RecruiterJobOffer>>> call(NoParams params) =>
      repository.getJobOffers();
}
