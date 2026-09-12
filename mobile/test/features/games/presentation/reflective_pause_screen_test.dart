import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/game_runtime_snapshot.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/data/reflective_pause_bank_loader.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_metrics.dart';
import 'package:zennyt/features/games/presentation/view/reflective_pause_screen.dart';

class _LongReflectionRepository extends GamesMockRepository {
  @override
  Future<GameSession> startSession(GameType gameType) async {
    final session = await super.startSession(gameType);
    return GameSession(
      id: session.id,
      gameType: session.gameType,
      status: session.status,
      compositeRaw: session.compositeRaw,
      compositeMax: session.compositeMax,
      normalized: session.normalized,
      attempts: session.attempts,
      startedAt: session.startedAt,
      runtime: const GameRuntimeSnapshot(
        settings: {'reflectiveThinkingTimeMs': 6000},
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La banque des 60 situations vient d'un asset : on la précharge une fois
  // pour que l'écran la retrouve en cache.
  setUpAll(() async {
    ReflectivePauseBankLoader.resetForTest();
    await ReflectivePauseBankLoader.load();
  });

  /// Les libellés viennent désormais de la banque du client et leur ORDRE est
  /// mélangé à chaque situation. On vise donc la réaction, jamais le texte ni
  /// la position.
  Finder choiceOf(ReflectivePauseResponseType type) =>
      find.byKey(ValueKey('reflective-choice-${type.wire}'));

  /// Coche une réaction, quelle que soit sa place dans la liste.
  ///
  /// La carte de situation porte maintenant l'emplacement du média et la
  /// question : les choix sont plus bas, et la liste ne les construit qu'une
  /// fois défilée jusqu'à eux.
  Future<void> tapChoice(
    WidgetTester tester,
    ReflectivePauseResponseType type,
  ) async {
    await tester.ensureVisible(choiceOf(type));
    await tester.tap(choiceOf(type));
    await tester.pump();
  }

  /// Dix situations imposées : huit dont la meilleure réaction est « respirer »
  /// (TR-007 à TR-058) et deux qui en attendent une autre — TR-001 attend
  /// « reformuler », TR-002 « demander ». Un parcours qui coche « respirer »
  /// partout obtient donc exactement huit recommandations sur dix.
  const situationsImposees = [
    'TR-007',
    'TR-009',
    'TR-013',
    'TR-020',
    'TR-042',
    'TR-046',
    'TR-047',
    'TR-058',
    'TR-001',
    'TR-002',
  ];

  Future<void> pumpGame(
    WidgetTester tester, {
    GamesMockRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Surface haute : la carte de situation porte désormais l'emplacement du
    // média, l'événement déclencheur et la question, et les cinq réponses
    // suivent. Sur 844 points de haut, une partie des choix sort du cadre et le
    // test passe son temps à défiler — ce qui mesure le défilement, pas le jeu.
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(
            repository ?? GamesMockRepository(),
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: ReflectivePauseScreen(
            now: tester.binding.clock.now,
            situationIds: situationsImposees,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reachGameplay(WidgetTester tester) async {
    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start mission'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets('la couverture et le tutoriel suivent les maquettes', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(find.text('Reflective Pause'), findsWidgets);
    expect(find.text('Impulse Control'), findsWidgets);
    expect(find.text('View tutorial'), findsOneWidget);
    expect(find.text('Start mission'), findsOneWidget);

    await tester.tap(find.text('View tutorial'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Train calm responses'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Wait'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Validate'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Validate'), findsOneWidget);
    expect(find.textContaining('Responses unlock only'), findsOneWidget);
    expect(find.textContaining('after all 10 moments'), findsOneWidget);
  });

  testWidgets('published thinking time extends the input lock and countdown', (
    tester,
  ) async {
    await pumpGame(tester, repository: _LongReflectionRepository());
    await reachGameplay(tester);
    await tester.pump(const Duration(milliseconds: 3100));
    expect(find.textContaining('Pause for'), findsOneWidget);
    expect(find.textContaining('Temps conseillé'), findsNothing);
    await tester.pump(const Duration(milliseconds: 3100));
    expect(find.textContaining('Temps conseillé'), findsOneWidget);
  });

  testWidgets('le timer bloque les choix et le menu pause reprend le chrono', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    expect(find.text('Moment 1 / 10'), findsOneWidget);
    expect(find.textContaining('Pause for'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Input mode'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);
    expect(find.text('Exit mission'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    expect(find.textContaining('Temps conseillé'), findsOneWidget);

    await tapChoice(tester, ReflectivePauseResponseType.breatheAnalyze);
    final validate = find.text('Validate response');
    await tester.ensureVisible(validate);
    await tester.tap(validate);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(find.text('Moment 2 / 10'), findsOneWidget);
  });

  testWidgets('les dix moments aboutissent au score serveur et aux insights', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump();
      await tapChoice(tester, ReflectivePauseResponseType.breatheAnalyze);
      final validate = find.text('Validate response');
      await tester.ensureVisible(validate);
      await tester.tap(validate);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Results preview'), findsOneWidget);
    // Huit des dix situations imposées attendent « respirer », que le parcours
    // coche partout : 3,0 (toutes les pauses) + 4,0 (aucune impulsive)
    // + 3 × 8/10 = 2,4 → 9,4, arrondi une seule fois.
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.text('Controlled reaction time'), findsOneWidget);
    expect(find.text('Non-impulsive responses'), findsOneWidget);
    expect(find.text('Ability to step back'), findsOneWidget);

    await tester.tap(find.text('View learning insights'));
    await tester.pumpAndSettle();
    expect(find.text('Learning insights'), findsOneWidget);
    expect(find.text('Strongest area'), findsOneWidget);
    expect(find.text('Impulsivity risk'), findsOneWidget);
    expect(find.text('Pressure pattern'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });
}
