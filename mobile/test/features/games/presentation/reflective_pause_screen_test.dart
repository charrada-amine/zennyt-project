import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/audio/sound_service.dart';
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
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

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

class _CountingRepository extends GamesMockRepository {
  int starts = 0;
  @override
  Future<GameSession> startSession(GameType gameType) {
    starts++;
    return super.startSession(gameType);
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
    Size size = const Size(390, 1500),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Surface haute : la carte de situation porte désormais l'emplacement du
    // média, l'événement déclencheur et la question, et les cinq réponses
    // suivent. Sur 844 points de haut, une partie des choix sort du cadre et le
    // test passe son temps à défiler — ce qui mesure le défilement, pas le jeu.
    tester.view.physicalSize = size * 3;
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
    for (var page = 0; page < 4; page++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Commencer la partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets('la couverture et le tutoriel suivent les maquettes', (
    tester,
  ) async {
    final repository = _CountingRepository();
    await pumpGame(tester, repository: repository);

    expect(find.text('Reflective Pause'), findsWidgets);
    expect(find.text('Impulse Control'), findsNothing);
    expect(find.text('View tutorial'), findsNothing);
    expect(find.text('Start mission'), findsOneWidget);

    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Train calm responses'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Comment jouer'), findsOneWidget);
    expect(find.text('Découvre la situation'), findsOneWidget);
    expect(
      find.textContaining('message ou observe la scène vidéo'),
      findsOneWidget,
    );
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('se débloquent à la fin'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 réponses'), findsOneWidget);
    expect(find.textContaining('naturellement'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('temps conseillé'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Après 10 situations'), findsOneWidget);
    expect(find.textContaining('Aucune correction'), findsOneWidget);
    expect(find.text('Commencer la partie'), findsOneWidget);
    expect(
      repository.starts,
      0,
      reason: 'aucune session pendant la lecture des cartes',
    );
    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();
    expect(repository.starts, 1);
    expect(find.text('Moment 1 / 10'), findsOneWidget);
  });

  testWidgets('published thinking time extends the input lock and countdown', (
    tester,
  ) async {
    await pumpGame(tester, repository: _LongReflectionRepository());
    await reachGameplay(tester);
    await tester.pump(const Duration(milliseconds: 3100));
    // Délai de réflexion publié à 6 s : le compteur tourne encore à 3,1 s.
    expect(
      find.byKey(const ValueKey('reflective-thinking-countdown')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 3100));
    expect(
      find.byKey(const ValueKey('reflective-thinking-countdown')),
      findsNothing,
    );
  });

  testWidgets('le timer bloque les choix et le menu pause reprend le chrono', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    expect(find.text('Moment 1 / 10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reflective-thinking-countdown')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Input mode'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);
    expect(find.text('Exit mission'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('reflective-thinking-countdown')),
      findsNothing,
    );

    await tapChoice(tester, ReflectivePauseResponseType.breatheAnalyze);
    final validate = find.text('Validate response');
    await tester.ensureVisible(validate);
    await tester.tap(validate);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(find.text('Moment 2 / 10'), findsOneWidget);
  });

  testWidgets(
    'les cartes de l’aide préservent le choix et le moment en cours',
    (tester) async {
      await pumpGame(tester, size: const Size(390, 844));
      await reachGameplay(tester);
      await tester.pump(const Duration(milliseconds: 3100));
      await tapChoice(tester, ReflectivePauseResponseType.breatheAnalyze);
      expect(
        find.descendant(
          of: choiceOf(ReflectivePauseResponseType.breatheAnalyze),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View rules / Help'));
      await tester.pumpAndSettle();
      expect(find.text('Découvre la situation'), findsOneWidget);
      for (var page = 0; page < 4; page++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Commencer la partie'), findsNothing);
      await tester.tap(find.text('Reprendre la partie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Moment 1 / 10'), findsOneWidget);
      expect(
        find.descendant(
          of: choiceOf(ReflectivePauseResponseType.breatheAnalyze),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(find.text('Validate response').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

    // Écran « Results preview » de la maquette, sur le barème serveur.
    expect(find.text('Results preview'), findsOneWidget);
    // Huit des dix situations imposées attendent « respirer », que le parcours
    // coche partout : 3,0 (toutes les pauses) + 4,0 (aucune impulsive)
    // + 3 × 8/10 = 2,4 → 9,4, arrondi une seule fois.
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.text('Level: Very good self-control'), findsOneWidget);
    expect(find.text('Controlled reaction time'), findsOneWidget);
    expect(find.text('Non-impulsive responses'), findsOneWidget);
    expect(find.text('Ability to step back'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('2.4 / 3'), findsOneWidget);
    // L'interprétation situe le score obtenu dans le barème.
    expect(
      find.textContaining('9 / 10 maps to Very good self-control.'),
      findsOneWidget,
    );

    await tester.tap(find.text('View learning insights'));
    await tester.pumpAndSettle();
    expect(find.text('Learning insights'), findsOneWidget);
    expect(find.text('Strongest area'), findsOneWidget);
    expect(find.text('Impulsivity risk'), findsOneWidget);
    expect(find.text('Pressure pattern'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });

  group('écran unique, fond mauve, sons', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('le plateau tient sur $size sans défilement', (tester) async {
        await pumpGame(tester, size: size);
        await reachGameplay(tester);
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'aucun débordement');
        expect(find.byType(Scrollable), findsNothing);
        for (final type in ReflectivePauseResponseType.values) {
          if (choiceOf(type).evaluate().isEmpty) continue;
          expect(choiceOf(type).hitTestable(), findsOneWidget);
          final text = find.descendant(
            of: choiceOf(type),
            matching: find.byType(Text),
          );
          final paragraph = tester.renderObject<RenderParagraph>(text.first);
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: 'réponse ${type.wire} coupée',
          );
        }
        expect(find.text('Validate response').hitTestable(), findsOneWidget);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, ZennytGamePalette.gameBlue);
      });
    }

    testWidgets('le tutoriel tient sur un petit écran', (tester) async {
      await pumpGame(tester, size: const Size(360, 640));
      await tester.tap(find.text('Start mission'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      for (var page = 0; page < 4; page++) {
        expect(find.text('Suivant').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Commencer la partie').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.text('Commencer la partie')).bottom,
        lessThan(640),
      );
    });

    testWidgets('la barre suit le temps conseillé de la situation', (
      tester,
    ) async {
      final bank = await ReflectivePauseBankLoader.load();
      final deadlineMs =
          bank.byId(situationsImposees.first).responseDeadlineSec * 1000;
      await pumpGame(tester);
      await reachGameplay(tester);
      double bar() => tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('reflective-time-bar')),
          )
          .value!;
      expect(bar(), 1.0, reason: 'pleine pendant la réflexion');
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();
      expect(bar(), 1.0, reason: 'le temps conseillé attend les 3 s');
      // Fin de la réflexion (3 s), puis la moitié du temps conseillé.
      await tester.pump(Duration(milliseconds: 1000 + deadlineMs ~/ 2));
      await tester.pump();
      expect(bar(), closeTo(0.5, 0.06), reason: 'à mi-temps conseillé');
      expect(find.text('Moment 1 / 10'), findsOneWidget);
      expect(
        // Le texte décompte avec la barre : la moitié du temps conseillé.
        find.textContaining(
          'Temps conseillé : ${(deadlineMs / 2000).ceil()} s',
        ),
        findsOneWidget,
      );
    });

    testWidgets('le compteur de réflexion vit dans la carte de la question', (
      tester,
    ) async {
      await pumpGame(tester);
      await reachGameplay(tester);
      final counter = find.byKey(
        const ValueKey('reflective-thinking-countdown'),
      );
      expect(counter, findsOneWidget);
      expect(find.text('3 s'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump();
      expect(counter, findsNothing);
      expect(find.text('Validate response'), findsOneWidget);
    });

    testWidgets('sons : décompte, pause et réponse', (tester) async {
      final played = <GameSfx>[];
      SoundService.debugOnSfx = played.add;
      addTearDown(() => SoundService.debugOnSfx = null);
      await pumpGame(tester);
      await reachGameplay(tester);
      final bank = await ReflectivePauseBankLoader.load();
      final deadlineMs =
          bank.byId(situationsImposees.first).responseDeadlineSec * 1000;

      // Réflexion : « 3 » dès l'ouverture du moment.
      expect(played, contains(GameSfx.timerDecrease), reason: 'tic de 3 s');

      // Puis « 2 », « 1 » et le son du déverrouillage.
      played.clear();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(played.where((s) => s == GameSfx.timerDecrease), hasLength(2));
      expect(played.where((s) => s == GameSfx.timerEnd), hasLength(1));

      // Temps conseillé : tics à 5, 4, 3, 2, 1 puis le son de fin.
      played.clear();
      final steps = (deadlineMs + 500) ~/ 100;
      for (var i = 0; i < steps; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(played.where((s) => s == GameSfx.timerDecrease), hasLength(5));
      expect(played.where((s) => s == GameSfx.timerEnd), hasLength(1));

      played.clear();
      await tapChoice(tester, ReflectivePauseResponseType.breatheAnalyze);
      expect(played, [GameSfx.buttonClick], reason: 'choix de réponse');

      played.clear();
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(played, contains(GameSfx.pauseClick));
    });
  });
}
