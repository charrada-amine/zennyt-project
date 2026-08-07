import '../../domain/entities/recruiter_job_offer.dart';
import '../../domain/entities/recruiter_test.dart';

abstract class CareersLocalDataSource {
  Future<List<RecruiterTest>> getTests();
  Future<List<RecruiterJobOffer>> getJobOffers();
}

/// Mock — espace recruteur (tests + offres publiées).
class CareersMockDataSource implements CareersLocalDataSource {
  static const _tests = <RecruiterTest>[
    RecruiterTest(id: 't1', name: 'Test 1'),
    RecruiterTest(id: 't2', name: 'Test 2'),
    RecruiterTest(id: 't3', name: 'Test 3'),
    RecruiterTest(id: 't4', name: 'Test 4'),
  ];

  static const _offers = <RecruiterJobOffer>[
    RecruiterJobOffer(
        id: 'o1', title: 'IT Programmer', company: 'Google inc',
        location: 'California, USA', salary: '\$25K/Mo',
        tags: ['IT', 'Full time'], postedAgo: '1 day ago',
        candidates: 30, successRate: 76),
    RecruiterJobOffer(
        id: 'o2', title: 'UI/UX Designer', company: 'Google inc',
        location: 'California, USA', salary: '\$15K/Mo',
        tags: ['IT', 'Full time'], postedAgo: '2 days ago',
        candidates: 30, successRate: 76),
    RecruiterJobOffer(
        id: 'o3', title: 'UX Designer', company: 'Google inc',
        location: 'California, USA', salary: '\$35K/Mo',
        tags: ['Design', 'Contract'], postedAgo: '3 days ago',
        candidates: 18, successRate: 64),
  ];

  @override
  Future<List<RecruiterTest>> getTests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tests;
  }

  @override
  Future<List<RecruiterJobOffer>> getJobOffers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _offers;
  }
}
