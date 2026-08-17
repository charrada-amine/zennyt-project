import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_score.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/score_breakdown.dart';
import 'package:zennyt/features/games/domain/repositories/games_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_screen.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'phase 1 enters phase 2, keeps choices neutral and hides bottom nav',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
    final repository = _FakeGamesRepository();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
          child: const MaterialApp(home: JeDecideScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Decision Journey'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));

      for (var page = 0; page < 3; page++) {
        await tapVisible(tester, find.byKey(const ValueKey('onboarding-next')));
      }

      expect(find.text('Create your player card'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('player-continue')));

      expect(find.text('Choose your avatar'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('avatar-continue')));

      expect(find.text('Practice round'), findsWidgets);
      await tapVisible(tester, find.byKey(const ValueKey('practice-start')));

      expect(find.text('Choosing a route'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('decision-more-menu')),
      );
      expect(
        find.byKey(const ValueKey('decision-pause-dialog')),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('decision-view-rules')),
      );
      expect(find.text('How to play'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('decision-rules-back')),
      );
      expect(
        find.byKey(const ValueKey('decision-pause-dialog')),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('decision-pause-dialog-resume')),
      );
      expect(find.text('Choosing a route'), findsOneWidget);

      final continueFinder = find.descendant(
        of: find.byKey(const ValueKey('practice-continue')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);

      await tapVisible(tester, find.byKey(const ValueKey('choice-faster')));

      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNotNull);
      expect(find.textContaining('correct'), findsNothing);
      expect(find.textContaining('wrong'), findsNothing);

      await tapVisible(tester, find.byKey(const ValueKey('practice-continue')));

      // Le contenu vient du backend : la vignette servie, pas un scénario codé
      // en dur, et le compteur part du premier item.
      expect(find.text('Situation numéro 0.'), findsOneWidget);
      expect(find.text('Scenario 01 / 30'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    },
  );

  testWidgets('saved checkpoint opens the welcome-back screen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'games.je_decide.saved_checkpoint': true,
      'games.je_decide.saved_item_index': 15,
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = _FakeGamesRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: JeDecideScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('decision-welcome-back')), findsOneWidget);
    expect(find.text('Continue from scenario 16'), findsOneWidget,
        reason: 'index 15 sauvegardé → item 16 affiché');
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('full journey reaches the final decision profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _FakeGamesRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: JeDecideScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
    for (var page = 0; page < 3; page++) {
      await tapVisible(tester, find.byKey(const ValueKey('onboarding-next')));
    }
    await tapVisible(tester, find.byKey(const ValueKey('player-continue')));
    await tapVisible(tester, find.byKey(const ValueKey('avatar-continue')));
    await tapVisible(tester, find.byKey(const ValueKey('practice-start')));
    await tapVisible(tester, find.byKey(const ValueKey('choice-faster')));
    await tapVisible(tester, find.byKey(const ValueKey('practice-continue')));

    Future<void> choose(int index) async {
      await tapVisible(tester, find.byKey(ValueKey('decision-option-$index')));
      await tapVisible(tester, find.byKey(const ValueKey('decision-continue')));
    }

    /// Passe l'écran de transition éventuellement intercalé entre deux blocs.
    Future<void> skipInterstitial() async {
      for (final key in const [
        'decision-next-scenario',
        'decision-checkpoint-continue',
        'decision-badge-continue',
        'decision-dimension-continue',
        'decision-encouragement-continue',
      ]) {
        final finder = find.byKey(ValueKey(key));
        if (finder.evaluate().isNotEmpty) {
          await tapVisible(tester, finder);
          return;
        }
      }
    }

    // Les 30 items de la forme, en alternant les options pour produire des
    // réponses distinctes.
    for (var i = 0; i < 30; i++) {
      await choose(i.isEven ? 0 : 1);
      await skipInterstitial();
    }

    // Le client a envoyé une réponse par item, sans jamais calculer de score.
    expect(repository.submitted, isNotNull);
    expect(repository.submitted!.items, hasLength(30));
    expect(
      repository.submitted!.items.every((item) => item.answered),
      isTrue,
    );
    expect(repository.submitted!.items.first.selectedOptionId, 'IT-0-o1');

    expect(
      find.byKey(const ValueKey('decision-journey-complete')),
      findsOneWidget,
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('decision-reveal-profile')),
    );
    expect(
      find.byKey(const ValueKey('decision-preparing-profile')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('decision-profile-title')),
      findsOneWidget,
    );
    expect(find.text('Normal'), findsOneWidget, reason: 'niveau serveur');
    // Le score s'anime de 0 → 71 : c'est celui renvoyé par le serveur.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('71'), findsOneWidget);
  });
}

/// Backend simulé : « Je Décide » ne peut pas être joué hors ligne (la banque de
/// 120 items et sa clé de correction restent serveur), donc les tests d'écran
/// servent eux-mêmes une forme et un score.
class _FakeGamesRepository implements GamesRepository {
  /// Taille de la forme servie — celle de la passation réelle.
  static const itemCount = 30;

  DecisionMetrics? submitted;

  static const _dimensions = [
    DecisionDimension.ii,
    DecisionDimension.er,
    DecisionDimension.dt,
    DecisionDimension.cs,
    DecisionDimension.re,
  ];

  @override
  Future<GameSession> startSession(GameType gameType) async => GameSession(
    id: 'fake-session',
    gameType: gameType,
    status: 'IN_PROGRESS',
    compositeRaw: 0,
    compositeMax: 100,
    normalized: 0,
    attempts: const [],
    startedAt: DateTime(2026),
  );

  @override
  Future<DecisionForm> decisionItems(String sessionId, {String language = 'fr'}) async {
    final perDimension = itemCount ~/ _dimensions.length;
    return DecisionForm(
      formCode: 'A',
      itemsPerDimension: perDimension,
      items: [
        for (var i = 0; i < itemCount; i++)
          DecisionFormItem(
            itemId: 'IT-$i',
            dimension: _dimensions[i ~/ perDimension],
            format: DecisionItemFormat.standard,
            vignette: 'Situation numéro $i.',
            task: 'Consigne numéro $i.',
            options: [
              DecisionFormOption(optionId: 'IT-$i-o1', label: 'Option A du $i'),
              DecisionFormOption(optionId: 'IT-$i-o2', label: 'Option B du $i'),
            ],
          ),
      ],
    );
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    submitted = metrics as DecisionMetrics;
    return GameSession(
      id: sessionId,
      gameType: GameType.decision,
      status: 'COMPLETED',
      compositeRaw: 71,
      compositeMax: 100,
      normalized: 71,
      startedAt: DateTime(2026),
      completedAt: DateTime(2026),
      attempts: [
        GameAttempt(
          miniGame: MiniGame.decisionCore,
          recordedAt: DateTime(2026),
          score: const GameScore(
            rawPoints: 71,
            maxPoints: 100,
            normalized: 71,
            level: 'Normal',
          ),
        ),
      ],
      scoreBreakdown: const [
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'II',
          detail: '6 items',
          points: 14,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'ER',
          detail: '6 items',
          points: 11,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'DT',
          detail: '6 items',
          points: 15,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'CS',
          detail: '6 items — notation provisoire (ne discrimine pas)',
          points: 12,
          maxPoints: 18,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'RE',
          detail: '6 items — notation provisoire (ne discrimine pas)',
          points: 12,
          maxPoints: 18,
        ),
      ],
    );
  }

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) => throw UnimplementedError();
}
