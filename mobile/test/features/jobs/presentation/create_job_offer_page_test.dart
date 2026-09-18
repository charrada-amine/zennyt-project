import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/pages/recruiter/jobs/create/create_job_offer_page.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';

class _FakeJobsRepository implements JobsRepository {
  final created = <CreateJobOfferParams>[];

  @override
  Future<List<JobOffer>> getJobOffers() async => const [];

  @override
  Future<List<JobPosition>> getJobPositions() async => const [
        JobPosition(id: 'pos-dev', name: 'Développeur', sector: 'Numérique', profileType: 'TECHNIQUE'),
        JobPosition(id: 'pos-data', name: 'Data Engineer', sector: 'Numérique', profileType: 'TECHNIQUE'),
        JobPosition(id: 'pos-ux', name: 'Graphiste / Designer', sector: 'Création', profileType: 'ARTISTIQUE'),
      ];

  @override
  Future<List<JobRoleProfile>> getJobRoleProfiles() async => const [];

  @override
  Future<JobOffer> createJobOffer(CreateJobOfferParams params) async {
    created.add(params);
    return JobOffer(
      id: 'new-job',
      recruiterId: 'rec',
      title: params.title,
      companyName: '',
      city: params.city,
      country: params.country,
      remote: params.remote,
      salaryMin: params.salaryMin,
      salaryMax: params.salaryMax,
      currency: '',
      contractType: params.contractType,
      workplaceType: params.workplaceType,
      experienceLevel: params.experienceLevel,
      fieldOfWork: '',
      description: params.description,
      responsibilities: '',
      minimumQualifications: '',
      preferredQualifications: '',
      whatWeOffer: '',
      howToApply: '',
      companyInfo: '',
      openToInternational: params.openToInternational,
      status: JobStatus.active,
      postedAt: DateTime(2026, 9, 18),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeJobsRepository> _pump(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _FakeJobsRepository();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('jobs list'))),
    GoRoute(path: '/create', builder: (_, _) => const CreateJobOfferPage()),
  ], initialLocation: '/');
  await tester.pumpWidget(ProviderScope(
    overrides: [jobsRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  ));
  router.push('/create');
  await tester.pumpAndSettle();
  return repo;
}

Finder _input(String key) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));

/// Le formulaire est une liste paresseuse : on défile jusqu'au champ avant d'y écrire.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await _reveal(tester, find.byKey(ValueKey(key)));
  await tester.enterText(_input(key), text);
  await tester.pump();
}

void main() {
  testWidgets('posting an empty offer shows what is missing instead of calling the API',
      (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('job-submit')));
    await tester.pumpAndSettle();

    expect(repo.created, isEmpty);
    expect(find.text('Job title is required'), findsOneWidget);
    expect(find.text('Pick a job family: it drives the Fit Score'), findsOneWidget);
    expect(find.text('0 of 4 required sections'), findsNothing,
        reason: 'contract & workplace always has a default, so at least 1 section is done');
    expect(find.text('1 of 4 required sections'), findsOneWidget);
  });

  testWidgets('salary max below min and a too-short description are rejected', (tester) async {
    await _pump(tester);
    await _type(tester, 'job-salary-min', '2600');
    await _type(tester, 'job-salary-max', '1800');
    await _type(tester, 'job-about', 'Too short');
    await tester.tap(find.byKey(const ValueKey('job-submit')));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const ValueKey('job-salary-max')));
    expect(find.text('Must be ≥ the minimum'), findsOneWidget);
    await _reveal(tester, find.byKey(const ValueKey('job-about')));
    expect(find.textContaining('more characters'), findsOneWidget);
  });

  testWidgets('salary fields only accept digits', (tester) async {
    await _pump(tester);
    await _type(tester, 'job-salary-min', '18a00€');
    expect(tester.widget<EditableText>(_input('job-salary-min')).controller.text, '1800');
  });

  testWidgets('a complete offer is posted with the chosen values', (tester) async {
    final repo = await _pump(tester);

    await _type(tester, 'job-title', 'Développeur Flutter Junior');
    await _reveal(tester, find.byKey(const ValueKey('job-position')));
    await tester.tap(find.byKey(const ValueKey('job-position')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('job-position-search')), 'data');
    await tester.pumpAndSettle();
    expect(find.text('Développeur'), findsNothing, reason: 'search filters the taxonomy');
    await tester.tap(find.text('Data Engineer'));
    await tester.pumpAndSettle();

    await _reveal(tester, find.text('Senior'));
    await tester.tap(find.text('Senior'));
    await _reveal(tester, find.text('Hybrid'));
    await tester.tap(find.text('Hybrid'));
    await _type(tester, 'job-city', 'Tunis');
    await _type(tester, 'job-country', 'Tunisia');
    await _type(tester, 'job-salary-min', '1800');
    await _type(tester, 'job-salary-max', '2600');
    await _type(tester, 'job-about',
        'Rejoins l’équipe data de Nexa Digital pour construire nos pipelines et tableaux de bord.');
    await tester.pump();
    expect(find.text('4 of 4 required sections'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('job-submit')));
    await tester.pumpAndSettle();

    final sent = repo.created.single;
    expect(sent.title, 'Développeur Flutter Junior');
    expect(sent.jobPositionId, 'pos-data');
    expect(sent.experienceLevel, ExperienceLevel.senior);
    expect(sent.workplaceType, WorkplaceType.hybrid);
    expect(sent.remote, isFalse);
    expect(sent.city, 'Tunis');
    expect(sent.salaryMin, 1800);
    expect(sent.salaryMax, 2600);
    expect(sent.salaryCurrency, 'TND');
    expect(find.text('jobs list'), findsOneWidget, reason: 'the form closes after posting');
  });

  testWidgets('no overflow with large text', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
