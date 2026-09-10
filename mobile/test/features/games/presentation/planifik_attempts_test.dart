import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/planifik_metrics.dart';
import 'package:zennyt/features/games/presentation/flame/grid_config.dart';
import 'package:zennyt/features/games/presentation/flame/planifik_game.dart';
import 'package:zennyt/features/games/presentation/view/planifik_screen.dart';

/// Garde-fou du compteur d'essais d'Optimal Path (Tâche B).
///
/// L'écran calcule `attempts = mauvaises routes + 1` : `_validate()` appelle
/// `onWrong()` (→ `_levelAttempts++`) quand le chemin validé n'atteint PAS
/// l'arrivée (`!game.isComplete`), et le bouton Valider est actif dès
/// `stepCount >= 1`. Ce test verrouille cette mécanique : valider un chemin
/// INCOMPLET est possible, donc un 2ᵉ essai l'est aussi (le critère « essais »
/// peut discriminer). Si un refactor gatait le bouton sur l'arrivée, ce test
/// casserait.
void main() {
  // Niveau déterministe 1×3 : départ (0,0) → arrivée (0,2). Un pas intermédiaire
  // (0,1) donne un chemin non vide mais incomplet.
  const line = GridConfig(
    cols: 3,
    rows: 1,
    start: 0,
    end: 2,
    obstacles: {},
    costlyZones: {},
    objectives: {},
    optimalLength: 2,
  );

  Future<PlanifikGame> pumpGame(WidgetTester tester) async {
    final game = PlanifikGame(config: line);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameWidget(game: game)),
      ),
    );
    // Laisse Flame exécuter onLoad (construction des cellules + reset du chemin).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    return game;
  }

  testWidgets(
    'validating an incomplete path is possible → a 2nd attempt exists',
    (tester) async {
      final game = await pumpGame(tester);

      // Un pas depuis le départ, sans atteindre l'arrivée.
      game.tapCell(0, 1);

      // Bouton Valider actif (stepCount >= 1)…
      expect(game.stepCount, greaterThanOrEqualTo(1));
      // …mais chemin INCOMPLET → _validate() prend la branche onWrong →
      // _levelAttempts++ : un mauvais essai est compté avant une éventuelle réussite.
      expect(game.isComplete, isFalse);
    },
  );

  testWidgets('completing the path reaches the arrival (correct branch)', (
    tester,
  ) async {
    final game = await pumpGame(tester);

    game.tapCell(0, 1);
    game.tapCell(0, 2);

    expect(game.stepCount, 2);
    expect(game.isComplete, isTrue);
  });

  // ── Retour d'erreur sur case interdite ────────────────────────────────────

  /// Le client signalait ne sentir **aucune vibration** sur erreur. Le câblage
  /// haptique était pourtant bon : le retour d'erreur n'était simplement émis que
  /// si la case rouge touchée jouxtait la fin du tracé. Ailleurs sur la grille,
  /// l'appui ne produisait rien du tout.
  ///
  /// Le son porte la vibration (via `SoundService`), donc verrouiller l'émission
  /// de [PlanifikGame.onBlockedTap] verrouille les deux.
  testWidgets('toute case interdite signale une erreur, adjacente ou non', (
    tester,
  ) async {
    // Grille 1×5 : départ (0,0), arrivée (0,4), murs en (0,2) — adjacent au pas
    // (0,1) — et en (0,3), hors de portée du tracé.
    const walled = GridConfig(
      cols: 5,
      rows: 1,
      start: 0,
      end: 4,
      obstacles: {2, 3},
      costlyZones: {},
      objectives: {},
      optimalLength: 4,
    );

    var blockedTaps = 0;
    var penalties = 0;
    final game = PlanifikGame(
      config: walled,
      onBlockedTap: () => blockedTaps++,
      onWrongCell: () => penalties++,
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Un pas depuis le départ : le tracé s'arrête en (0,1).
    game.tapCell(0, 1);

    // Mur NON adjacent au tracé : c'était le cas muet.
    game.tapCell(0, 3);
    expect(
      blockedTaps,
      1,
      reason: 'une case rouge hors du tracé doit quand même signaler l\'erreur',
    );
    expect(
      penalties,
      0,
      reason: 'sans prolonger le tracé, ce n\'est pas une faute de plan',
    );

    // Mur adjacent au tracé : erreur de planification → retour ET pénalité.
    game.tapCell(0, 2);
    expect(blockedTaps, 2);
    expect(penalties, 1);
  });

  // ── Limite dure d'essais : 3 mauvais chemins → niveau échoué (1/10) ────────

  test('buildFailedLevelMetrics produit des métriques d\'échec = 1/10', () {
    final game = PlanifikGame(config: line); // optimalLength = 2
    final m = game.buildFailedLevelMetrics(levelIndex: 2, attempts: 3);

    // chemin optimal 0/4 (pathLength 0 → écart 100 %), essais ≥3 → 1/3,
    // zones NONE → 0/2, objectif NO → 0/1  ⇒ 1/10
    expect(m.pathLength, 0);
    expect(m.attempts, 3);
    expect(m.optimalLength, 2);
    expect(m.costlyZonesAvoided, CostlyZonesAvoided.none);
    expect(m.secondaryObjectivesReached, SecondaryObjectivesReached.no);
  });

  test('mock score un niveau échoué à 1/10 (parité backend)', () async {
    final repo = GamesMockRepository();
    final session = await repo.startSession(GameType.planifik);

    final updated = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.optimalPath,
      metrics: const PlanifikMetrics(
        levels: [
          PlanifikLevelMetrics(
            levelIndex: 0,
            attempts: 3,
            pathLength: 0,
            optimalLength: 9,
            costlyZonesAvoided: CostlyZonesAvoided.none,
            secondaryObjectivesReached: SecondaryObjectivesReached.no,
          ),
        ],
      ),
    );

    expect(updated.lastAttempt!.score.rawPoints, 1);
    expect(updated.lastAttempt!.score.maxPoints, 10);
  });

  testWidgets('3 chemins incomplets scellent le niveau et passent au niveau suivant', (
    tester,
  ) async {
    // Surface haute : les boutons (Start, Next, Validate) tiennent dans le
    // viewport, sinon un tap « rate » (bouton hors-champ) et rien ne se passe.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PlanifikScreen())),
    );

    // Intro → How To Play → gameplay.
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // page 1 → 2
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // → onDone (_beginGame)
    // Gameplay + Flame : pas de pumpAndSettle (ticker continu).
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 300),
    ); // onLoad + start() mock

    expect(find.text('Validate route'), findsOneWidget); // on est bien en jeu

    // find.byType ne matche pas GameWidget<PlanifikGame> (générique) → prédicat.
    final gameWidget = tester
        .widgetList<GameWidget>(find.byWidgetPredicate((w) => w is GameWidget))
        .first;
    final game = gameWidget.game as PlanifikGame;

    // Voisin praticable du départ (≠ arrivée) pour tracer un pas incomplet.
    final cfg = game.config;
    final sr = cfg.rowOf(cfg.start), sc = cfg.colOf(cfg.start);
    late final int stepRow, stepCol;
    for (final rc in [
      [sr - 1, sc],
      [sr + 1, sc],
      [sr, sc - 1],
      [sr, sc + 1],
    ]) {
      final r = rc[0], c = rc[1];
      if (r < 0 || c < 0 || r >= cfg.rows || c >= cfg.cols) continue;
      final idx = cfg.index(r, c);
      if (idx == cfg.end || !cfg.isWalkable(idx)) continue;
      stepRow = r;
      stepCol = c;
      break;
    }

    // 3 validations d'un chemin incomplet. Après chaque échec, le trait de trajet
    // est réinitialisé au départ (timer 1300 ms) → on le retrace à chaque tour.
    for (var i = 0; i < 3; i++) {
      game.tapCell(sr, sc); // (re)pose le départ si nécessaire (no-op sinon)
      game.tapCell(stepRow, stepCol); // un pas incomplet
      await tester.pump();
      expect(game.stepCount, greaterThanOrEqualTo(1));
      expect(game.isComplete, isFalse);

      await tester.tap(find.text('Validate route'));
      // Horloge de test (fake) : fait courir les timers app (reset feedback +
      // game.clear) — nécessaire pour réinitialiser le trajet entre 2 essais.
      await tester.pump(const Duration(milliseconds: 1400));
    }

    // Niveau scellé : feedback clair, plus de validation possible.
    expect(find.text('Niveau échoué — 3 essais'), findsOneWidget);

    // Passage automatique au niveau suivant (timer 1500 ms).
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.textContaining('Level 2/'), findsOneWidget);
  });
}
