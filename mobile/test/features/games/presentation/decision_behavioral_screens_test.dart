import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/bart_config.dart';
import 'package:zennyt/features/games/domain/entities/bart_metrics.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/game_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_session.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/ist_metrics.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/bart_screen.dart';
import 'package:zennyt/features/games/presentation/view/ist_screen.dart';

/// Mock hors ligne réel (barème identique au serveur), qui garde la trace de la
/// session et des métriques soumises pour les vérifier.
class _RecordingMock extends GamesMockRepository {
  GameSession? started;
  GameMetrics? submitted;
  MiniGame? submittedMiniGame;

  @override
  Future<GameSession> startSession(GameType gameType) async =>
      started = await super.startSession(gameType);

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) {
    submitted = metrics;
    submittedMiniGame = miniGame;
    return super.submitResult(sessionId: sessionId, miniGame: miniGame, metrics: metrics);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_RecordingMock> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(430 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = _RecordingMock();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('BART', () {
    testWidgets('couverture conforme à la maquette', (tester) async {
      await pump(tester, const BartScreen());
      expect(find.text('BART'), findsOneWidget);
      expect(find.text('Gonfler ou collecter'), findsOneWidget);
      expect(find.text('Decision Making'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('essais pratiques'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('gonfler remplit la réserve, collecter la met en banque', (tester) async {
      final repository = await pump(tester, const BartScreen());
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(find.text('Entraînement 1 / 2'), findsOneWidget);
      final points = BartConfig.explosionPoints(repository.started!.id);
      final safe = (points.first - 1).clamp(0, 3);
      for (var i = 0; i < safe; i++) {
        await tapKey(tester, 'bart-pump');
      }
      expect(find.text('$safe pts'), findsWidgets);
      await tapKey(tester, 'bart-collect');
      await tester.pumpAndSettle();
      expect(find.text('Réserve collectée'), findsWidgets);
      expect(find.text('+$safe pts'), findsOneWidget);
    });

    testWidgets('le ballon éclate exactement au point serveur ; partie complète jusqu\'aux résultats',
        (tester) async {
      final repository = await pump(tester, const BartScreen());
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      final points = BartConfig.explosionPoints(repository.started!.id);

      for (var balloon = 0; balloon < BartConfig.totalBalloonCount; balloon++) {
        // Stratégie : 6 pompes puis collecte — ou éclatement avant.
        var burst = false;
        for (var p = 1; p <= 6; p++) {
          await tapKey(tester, 'bart-pump');
          if (find.text('Ballon éclaté').evaluate().isNotEmpty) {
            expect(p, points[balloon], reason: 'éclatement au mauvais moment');
            burst = true;
            break;
          }
        }
        if (!burst) {
          expect(points[balloon], greaterThan(6));
          await tapKey(tester, 'bart-collect');
        }
        await tester.pumpAndSettle();
        await tapKey(tester, 'bart-next');
        await tester.pumpAndSettle();
      }

      expect(repository.submittedMiniGame, MiniGame.bartCore);
      final metrics = repository.submitted! as BartMetrics;
      expect(metrics.balloons, hasLength(BartConfig.totalBalloonCount));
      expect(metrics.sessionCompleted, isTrue);
      expect(find.text('BART completed'), findsOneWidget);
    });
  });

  group('IST', () {
    testWidgets('couverture conforme à la maquette', (tester) async {
      await pump(tester, const IstScreen());
      expect(find.text('IST'), findsOneWidget);
      expect(find.text('Observer puis décider'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('ouvrir une case révèle sa couleur et compte ; confiance obligatoire ou passée',
        (tester) async {
      await pump(tester, const IstScreen());
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(find.text('Entraînement 1 / 2'), findsOneWidget);
      expect(find.text('Gain fixe'), findsOneWidget);
      expect(find.text('100 pts'), findsOneWidget);
      await tapKey(tester, 'ist-box-0');
      await tapKey(tester, 'ist-box-0'); // une case ne s'ouvre qu'une fois
      expect(find.text('1 / 25'), findsOneWidget);

      await tapKey(tester, 'ist-choose-BLUE');
      await tester.pumpAndSettle();
      expect(find.text('À quel point êtes-vous sûr ?'), findsOneWidget);
      final confirm = tester.widget<ButtonStyleButton>(
        find.descendant(
          of: find.byKey(const ValueKey('ist-confirm')),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(confirm.onPressed, isNull, reason: 'Confirmer exige un niveau de confiance');
      await tapKey(tester, 'ist-skip');
      await tester.pumpAndSettle();
      expect(find.text('Entraînement 2 / 2'), findsOneWidget);
      expect(find.text('Gain décroissant'), findsOneWidget);
      expect(find.text('250 pts'), findsOneWidget);
      await tapKey(tester, 'ist-box-3');
      expect(find.text('240 pts'), findsOneWidget);
    });

    testWidgets('partie complète : 22 essais soumis, résultats affichés', (tester) async {
      final repository = await pump(tester, const IstScreen());
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      for (var trial = 0; trial < 22; trial++) {
        for (var box = 0; box < 5; box++) {
          await tapKey(tester, 'ist-box-$box');
        }
        await tapKey(tester, 'ist-choose-BLUE');
        await tester.pumpAndSettle();
        await tapKey(tester, 'ist-confidence-3');
        await tapKey(tester, 'ist-confirm');
        await tester.pumpAndSettle();
      }

      expect(repository.submittedMiniGame, MiniGame.informationSamplingCore);
      final metrics = repository.submitted! as IstMetrics;
      expect(metrics.trials, hasLength(22));
      expect(metrics.trials.every((t) => t.openings.length == 5), isTrue);
      expect(metrics.trials.every((t) => t.confidence == 3), isTrue);
      expect(find.text('IST completed'), findsOneWidget);
    });
  });
}
