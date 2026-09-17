import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
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

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    for (final channel in [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/zennyt-bg-music',
      'xyz.luan/audioplayers/events/zennyt-scoreboard',
    ]) {
      messenger.setMockStreamHandler(
        EventChannel(channel),
        _SilentStreamHandler(),
      );
    }
    SoundService.instance.setSfxEnabled(false);
    SoundService.instance.setMusicEnabled(false);
  });

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<_FakeGamesRepository> showEntry(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _FakeGamesRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          sharedPreferencesProvider.overrideWithValue(preferences),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              disableAnimations: reduceMotion,
            ),
            child: const RepaintBoundary(
              key: ValueKey('je-decide-entry-capture'),
              child: JeDecideScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('cadre stable à l’entrée des règles et au retour accueil', (
    tester,
  ) async {
    final repository = await showEntry(tester);
    final header = find.byKey(const ValueKey('decision-journey-header'));
    final navigation = find.byType(AppBottomNav);
    final headerRect = tester.getRect(header);
    final navigationRect = tester.getRect(navigation);
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.getRect(header), headerRect);
    expect(tester.getRect(navigation), navigationRect);
    expect(find.byTooltip('Back'), findsOneWidget);
    final outgoing = find.byKey(const ValueKey('welcome-customize'));
    expect(outgoing, findsOneWidget);
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(of: outgoing, matching: find.byType(IgnorePointer)),
          )
          .any((pointer) => pointer.ignoring),
      isTrue,
      reason: 'les actions de l’accueil sortant ne répondent plus',
    );
    await tester.pumpAndSettle();
    expect(find.text('Comment jouer'), findsOneWidget);
    expect(find.text('Étape 1 sur 3'), findsOneWidget);
    final illustration = find.byKey(
      const ValueKey('je-decide-tutorial-image-0'),
    );
    await tester.runAsync(() async {
      await precacheImage(
        tester.widget<Image>(illustration).image,
        tester.element(illustration),
      );
    });
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RawImage>(
            find.descendant(of: illustration, matching: find.byType(RawImage)),
          )
          .image,
      isNotNull,
    );
    await expectLater(
      find.byKey(const ValueKey('je-decide-entry-capture')),
      matchesGoldenFile('goldens/je-decide-tutorial-entry.png'),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.getRect(header), headerRect);
    expect(tester.getRect(navigation), navigationRect);
    await tester.pumpAndSettle();
    expect(find.text('Commencer'), findsOneWidget);
    expect(repository.sessionsStarted, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mouvement réduit : accès direct aux règles sans accueil sortant',
    (tester) async {
      final repository = await showEntry(tester, reduceMotion: true);
      await tester.tap(find.byKey(const ValueKey('welcome-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome-start')), findsNothing);
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(repository.sessionsStarted, 0);
      await tapVisible(tester, find.byTooltip('Back'));
      expect(find.text('Commencer'), findsOneWidget);
      expect(find.text('Étape 1 sur 3'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'personnalisation facultative, retour accueil et entrée dans la partie',
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
            currentUserProvider.overrideWithValue(null),
            sharedPreferencesProvider.overrideWithValue(preferences),
            gamesRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: JeDecideScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Decision Journey'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('welcome-customize')));

      expect(find.text('Create your player card'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Lina');
      await tapVisible(tester, find.byKey(const ValueKey('player-continue')));

      expect(find.text('Choose your avatar'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('avatar-continue')));

      expect(find.text('Comment jouer'), findsOneWidget);
      expect(find.text('Essayer l’exemple'), findsNothing);
      await tapVisible(tester, find.byTooltip('Back'));
      expect(find.text('Commencer'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('welcome-customize')));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Lina',
      );
      await tapVisible(tester, find.byTooltip('Back'));
      await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      for (var page = 0; page < 2; page++) {
        await tapVisible(tester, find.text('Suivant'));
      }
      await tapVisible(tester, find.text('Essayer l’exemple'));

      expect(find.text('Choosing a route'), findsOneWidget);
      expect(find.text('Exemple d’entraînement'), findsOneWidget);
      expect(find.text('Practice 1 / 2'), findsNothing);
      expect(repository.sessionsStarted, 0);
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
      expect(find.text('Comment jouer'), findsOneWidget);
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
      expect(repository.sessionsStarted, 1);
      expect(find.byType(AppBottomNav), findsNothing);
    },
  );

  testWidgets(
    'accueil avec logo, texte court et accès direct aux trois règles',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = _FakeGamesRepository();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            sharedPreferencesProvider.overrideWithValue(preferences),
            gamesRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: RepaintBoundary(
              key: ValueKey('je-decide-welcome-capture'),
              child: JeDecideScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final logo = find.byKey(const ValueKey('je-decide-welcome-logo'));
      await tester.runAsync(() async {
        await precacheImage(
          tester.widget<Image>(logo).image,
          tester.element(logo),
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('Je Décide'), findsOneWidget);
      expect(find.text('30 questions'), findsOneWidget);
      expect(find.text('Jusqu’à 30 min'), findsOneWidget);
      expect(find.text('How it works'), findsNothing);
      expect(find.text('Personnaliser (facultatif)'), findsOneWidget);
      expect(
        tester
            .widget<RawImage>(
              find.descendant(of: logo, matching: find.byType(RawImage)),
            )
            .image,
        isNotNull,
      );
      await expectLater(
        find.byKey(const ValueKey('je-decide-welcome-capture')),
        matchesGoldenFile('goldens/je-decide-welcome.png'),
      );
      await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(repository.sessionsStarted, 0);
    },
  );

  testWidgets('accueil défilable sur petit écran avec texte à 200 %', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 600),
              textScaler: TextScaler.linear(2),
            ),
            child: const JeDecideScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
    expect(find.text('Étape 1 sur 3'), findsOneWidget);
    for (var page = 0; page < 2; page++) {
      await tapVisible(tester, find.text('Suivant'));
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.text('Essayer l’exemple'));
    expect(
      tester.getRect(find.text('Essayer l’exemple')).bottom,
      lessThan(600),
    );
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.byTooltip('Back'));
    await tapVisible(tester, find.byKey(const ValueKey('welcome-customize')));
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Le test « saved checkpoint opens the welcome-back screen » vivait ici.
  //
  // La reprise a été retirée : le point de sauvegarde ne conservait que l'index
  // de la question, jamais les réponses, si bien qu'un parcours repris renvoyait
  // au serveur toutes les questions précédentes comme « non répondues » — trois
  // perdues sur quatre à la mesure — pendant que l'écran affirmait « Your
  // previous choices are saved ».
  //
  // La garantie que des clés résiduelles dans les préférences ne déclenchent
  // plus rien est vérifiée par « aucun écran de reprise, aucun point de
  // sauvegarde » dans `je_decide_gameplay_test.dart`, qui les sème justement
  // avant de monter l'écran.

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
          currentUserProvider.overrideWithValue(null),
          sharedPreferencesProvider.overrideWithValue(preferences),
          gamesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: JeDecideScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
    for (var page = 0; page < 2; page++) {
      await tapVisible(tester, find.text('Suivant'));
    }
    await tapVisible(tester, find.text('Essayer l’exemple'));
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
    expect(repository.submitted!.items.every((item) => item.answered), isTrue);
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
    expect(find.text('71%'), findsOneWidget);
  });
}

/// Backend simulé : « Je Décide » ne peut pas être joué hors ligne (la banque de
/// 120 items et sa clé de correction restent serveur), donc les tests d'écran
/// servent eux-mêmes une forme et un score.
class _FakeGamesRepository implements GamesRepository {
  /// Taille de la forme servie — celle de la passation réelle.
  static const itemCount = 30;

  DecisionMetrics? submitted;
  int sessionsStarted = 0;

  static const _dimensions = [
    DecisionDimension.ii,
    DecisionDimension.er,
    DecisionDimension.dt,
    DecisionDimension.cs,
    DecisionDimension.re,
  ];

  @override
  Future<GameSession> startSession(GameType gameType) async {
    sessionsStarted++;
    return GameSession(
      id: 'fake-session',
      gameType: gameType,
      status: 'IN_PROGRESS',
      compositeRaw: 0,
      compositeMax: 100,
      normalized: 0,
      attempts: const [],
      startedAt: DateTime(2026),
    );
  }

  @override
  Future<DecisionForm> decisionItems(
    String sessionId, {
    String language = 'fr',
  }) async {
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

class _SilentStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
