import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/recruiter_job_offer.dart';
import '../entities/recruiter_test.dart';

abstract class CareersRepository {
  Future<Either<Failure, List<RecruiterTest>>> getTests();
  Future<Either<Failure, List<RecruiterJobOffer>>> getJobOffers();
}
