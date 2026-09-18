import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/pages/job_offer_detail_page.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';

JobOffer _offer({MyApplication? myApplication, String? assessmentId}) => JobOffer(
      id: 'job-1',
      recruiterId: 'rec-1',
      title: 'Développeur Flutter Junior avec un titre volontairement long',
      companyName: 'Nexa Digital',
      city: 'Tunis',
      country: 'Tunisia',
      remote: false,
      salaryMin: 1800,
      salaryMax: 2600,
      salaryCurrency: 'TND',
      currency: 'TND',
      contractType: ContractType.fullTime,
      workplaceType: WorkplaceType.hybrid,
      experienceLevel: ExperienceLevel.junior,
      fieldOfWork: '',
      description: 'Rejoins notre équipe mobile. ' * 20,
      responsibilities: 'Développer des fonctionnalités Flutter. ' * 10,
      minimumQualifications: 'Bac+3.',
      preferredQualifications: 'Riverpod.',
      whatWeOffer: 'Mentorat.',
      howToApply: 'Postule dans l’app.',
      companyInfo: 'Nexa Digital construit des apps mobiles.',
      assessmentId: assessmentId,
      openToInternational: false,
      status: JobStatus.active,
      postedAt: DateTime(2026, 9, 18),
      myApplication: myApplication,
    );

class _FakeJobsRepository implements JobsRepository {
  _FakeJobsRepository(this.offer, {this.applyResult = MyApplication.applied});

  final JobOffer offer;
  final MyApplication applyResult;
  final applied = <(String, bool)>[];

  @override
  Future<JobOffer> getJobOfferById(String id) async => offer;

  @override
  Future<MyApplication> applyToJobOffer(String jobOfferId, {bool reconsider = false}) async {
    applied.add((jobOfferId, reconsider));
    return applyResult;
  }

  @override
  Future<TestResult?> getMyTestResult(String jobOfferId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeJobsRepository> _pump(
  WidgetTester tester,
  JobOffer offer, {
  MyApplication applyResult = MyApplication.applied,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _FakeJobsRepository(offer, applyResult: applyResult);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      jobsRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWithValue(null),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const JobOfferDetailPage(jobId: 'job-1'),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('Apply records the application and shows it as sent', (tester) async {
    final repo = await _pump(tester, _offer(myApplication: MyApplication.none));

    await tester.tap(find.byKey(const ValueKey('job-apply')));
    await tester.pumpAndSettle();

    expect(repo.applied, [('job-1', false)]);
    expect(find.byKey(const ValueKey('job-apply-status-applied')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-apply')), findsNothing);
  });

  testWidgets('applying when the recruiter already liked the profile opens a match',
      (tester) async {
    await _pump(tester, _offer(myApplication: MyApplication.none),
        applyResult: MyApplication.matched);

    await tester.tap(find.byKey(const ValueKey('job-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-apply-status-matched')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-open-chat')), findsOneWidget);
  });

  testWidgets('an existing application is shown on open, without an Apply button',
      (tester) async {
    await _pump(tester, _offer(myApplication: MyApplication.applied));

    expect(find.byKey(const ValueKey('job-apply-status-applied')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-apply')), findsNothing);
  });

  testWidgets('a passed offer can still be applied to (withdraws the pass first)',
      (tester) async {
    final repo = await _pump(tester, _offer(myApplication: MyApplication.passed));

    await tester.tap(find.byKey(const ValueKey('job-apply')));
    await tester.pumpAndSettle();

    expect(repo.applied, [('job-1', true)]);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 640), 2.0),
    (const Size(390, 844), 1.5),
  ]) {
    testWidgets('no overflow on ${size.width.toInt()}x${size.height.toInt()} at text x$scale',
        (tester) async {
      await _pump(tester, _offer(myApplication: MyApplication.none, assessmentId: 'a-1'),
          size: size, textScale: scale);
      expect(tester.takeException(), isNull);

      // The description stays reachable: scrolling brings the hard-skills card and
      // the sections into view instead of squeezing them to nothing.
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('job-apply')), findsOneWidget);
    });
  }
}
