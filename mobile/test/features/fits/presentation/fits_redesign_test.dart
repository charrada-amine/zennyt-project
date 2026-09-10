import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/auth/domain/entities/app_user.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/fits/domain/entities/swipe_result.dart';
import 'package:zennyt/features/fits/domain/repositories/fits_repository.dart';
import 'package:zennyt/features/fits/presentation/providers/swipe_deck_provider.dart';
import 'package:zennyt/features/fits/presentation/view/fits_screen.dart';
import 'package:zennyt/features/fits/presentation/widgets/fit_card_data.dart';
import 'package:zennyt/features/fits/presentation/widgets/tinder_card.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/search/presentation/pages/candidate_filter_page.dart';
import 'package:zennyt/features/search/presentation/providers/search_provider.dart';

JobOffer _job(String id, String title) => JobOffer(
  id: id,
  recruiterId: 'recruiter',
  title: title,
  companyName: 'Studio',
  city: 'Tunis',
  country: 'Tunisia',
  remote: true,
  salaryMin: 12000,
  salaryMax: 18000,
  currency: 'EUR',
  contractType: ContractType.fullTime,
  workplaceType: WorkplaceType.remote,
  experienceLevel: ExperienceLevel.senior,
  fieldOfWork: 'Design',
  description: '',
  responsibilities: '',
  minimumQualifications: '',
  preferredQualifications: '',
  whatWeOffer: '',
  howToApply: '',
  companyInfo: '',
  openToInternational: true,
  status: JobStatus.active,
  postedAt: DateTime(2026, 9, 7),
);

class _Repository extends Fake implements FitsRepository {
  final swipes = <String>[];
  final jobs = [_job('a', 'Product designer'), _job('b', 'Software engineer')];
  @override
  Future<List<JobOffer>> getCandidateDeck() async => jobs;
  @override
  Future<List<String>> getSwipedTargetIds({String? jobOfferId}) async => [];
  @override
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeTargetType targetType,
    required String jobOfferId,
    required SwipeDirection direction,
  }) async {
    swipes.add(targetId);
    return SwipeResult(swipeId: targetId, direction: direction, matched: false);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  double scale = 1,
  _Repository? repo,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => screen)],
  );
  addTearDown(router.dispose);
  final app = MaterialApp.router(
    routerConfig: router,
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
  );
  await tester.pumpWidget(
    container == null
        ? ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(
                const AppUser(
                  id: 'u',
                  firstName: 'Test',
                  lastName: 'User',
                  email: 'test@example.test',
                ),
              ),
              if (repo != null) fitsRepositoryProvider.overrideWithValue(repo),
            ],
            child: app,
          )
        : UncontrolledProviderScope(container: container, child: app),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Browse search filters visible cards without changing the swipe target',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, const FitsScreen(), repo: repo);
      expect(find.text('Product designer'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'engineer');
      await tester.pumpAndSettle();
      expect(find.text('Product designer'), findsNothing);
      expect(find.text('Software engineer'), findsOneWidget);
      await tester.tap(find.text('Match'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Like'));
      await tester.pumpAndSettle();
      expect(repo.swipes, ['a']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Browse cards open readable details in dark mode with large text',
    (tester) async {
      await _pump(
        tester,
        const FitsScreen(),
        dark: true,
        scale: 1.4,
        repo: _Repository(),
      );
      await tester.tap(find.text('Product designer'));
      await tester.pumpAndSettle();
      expect(find.byType(FitCardContent), findsOneWidget);
      expect(find.text('Job Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cancelled horizontal drag resets, committed drag fires once', (
    tester,
  ) async {
    var likes = 0;
    final data = FitCardData.fromJobOffer(_job('a', 'Product designer'));
    await _pump(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: TinderCard(
            data: data,
            onSwipeLeft: () {},
            onSwipeRight: () => likes++,
            isFront: true,
          ),
        ),
      ),
    );
    await tester.drag(find.byType(TinderCard), const Offset(45, 0));
    await tester.pumpAndSettle();
    expect(likes, 0);
    await tester.drag(find.byType(TinderCard), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(likes, 1);
    await tester.drag(find.byType(TinderCard), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(likes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Filter controls expose the current level vocabulary and preserve selections',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(searchFiltersProvider.notifier)
          .apply(const SearchFilters(level: 'LEAD', workplace: 'REMOTE'));
      await _pump(tester, const CandidateFilterPage(), container: container);
      final lead = find.widgetWithText(ChoiceChip, 'Lead');
      expect(tester.widget<ChoiceChip>(lead).selected, isTrue);
      expect(find.widgetWithText(ChoiceChip, 'Executive'), findsNothing);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(container.read(searchFiltersProvider).isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
