import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/task_scheduling_metrics.dart';

/// Parité mock ⇄ backend du barème « Planning journalier » (Planifik #2).
///
/// Le mock doit produire EXACTEMENT le score du serveur : une démonstration
/// hors ligne qui noterait autrement qu'une passation réelle donnerait au
/// client une impression fausse du jeu.
void main() {
  Future<int> score(TaskSchedulingMetrics m) async {
    final repo = GamesMockRepository();
    final session = await repo.startSession(GameType.planifik);
    final updated = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.taskScheduling,
      metrics: m,
    );
    return updated.lastAttempt!.score.rawPoints;
  }

  /// Planning parfait, ajustable composante par composante.
  TaskSchedulingMetrics parfait({
    int edgeCount = 10,
    int edgesRespected = 10,
    int directViolations = 0,
    int timingCount = 6,
    int timingRespected = 6,
    bool collisionFree = true,
    double deadTimeRatio = 0.0,
    int proactive = 0,
    int reactive = 0,
  }) => TaskSchedulingMetrics(
    universeId: 'restaurant',
    dependencyEdgeCount: edgeCount,
    dependencyEdgesRespected: edgesRespected,
    directDependencyViolations: directViolations,
    timingConstraintCount: timingCount,
    timingConstraintsRespected: timingRespected,
    collisionFree: collisionFree,
    deadTimeRatio: deadTimeRatio,
    proactiveAdjustments: proactive,
    reactiveAdjustments: reactive,
  );

  test('planning parfait = 10/10', () async {
    expect(await score(parfait()), 10);
  });

  group('dépendances — au prorata, plus en tout-ou-rien', () {
    test('la moitié des arêtes vaut la moitié des points', () async {
      // 1,5 + 3 + 2 + 2 = 8,5 -> arrondi 9. L'ancien barème donnait 0 sur cette
      // composante : un joueur à moitié correct valait un joueur au hasard.
      expect(await score(parfait(edgesRespected: 5)), 9);
    });

    test('une violation directe coûte un point plein', () async {
      // 3 − 1 = 2, puis 3 + 2 + 2 = 9. Le référentiel traite la règle enfreinte
      // comme une erreur distincte d'un mauvais arbitrage d'ordre.
      expect(await score(parfait(directViolations: 1)), 9);
    });

    test('la composante ne descend jamais sous zéro', () async {
      expect(await score(parfait(directViolations: 9)), 7); // 0 + 3 + 2 + 2
    });
  });

  group('gestion du temps — divisée par le n RÉEL de l\'univers', () {
    test('5 sur 6 contraintes', () async {
      // 3 + 2,5 + 2 + 2 = 9,5 -> 10.
      expect(await score(parfait(timingRespected: 5)), 10);
    });

    test('le même nombre de réussites vaut moins sur un univers plus exigeant',
        () async {
      // 5/7 vaut moins que 5/6 : c'est précisément ce que le référentiel
      // demande en interdisant un dénominateur constant.
      final sur6 = await score(parfait(timingCount: 6, timingRespected: 5));
      final sur7 = await score(parfait(timingCount: 7, timingRespected: 5));
      expect(sur7, lessThan(sur6));
    });
  });

  group('cohérence séquentielle', () {
    test('une collision coûte son point', () async {
      expect(await score(parfait(collisionFree: false)), 9);
    });

    test('temps mort : moins de 10 % garde le point entier', () async {
      expect(await score(parfait(deadTimeRatio: 0.09)), 10);
    });

    test('entre 10 et 25 %, un demi-point', () async {
      // 3 + 3 + 1,5 + 2 = 9,5 -> 10 après arrondi. Le demi-point existe bien
      // dans le calcul, même si l'entier final le masque ici.
      expect(await score(parfait(deadTimeRatio: 0.20)), 10);
    });

    test('au-delà de 25 %, plus rien', () async {
      expect(await score(parfait(deadTimeRatio: 0.40)), 9); // 3+3+1+2
    });
  });

  group('autorégulation — proactif contre réactif', () {
    test('une seule correction garde les 2 points', () async {
      expect(await score(parfait(proactive: 1)), 10);
    });

    test('deux à trois corrections : 1 point', () async {
      expect(await score(parfait(proactive: 2)), 9);
    });

    test('au-delà de trois corrections : plus rien', () async {
      expect(await score(parfait(proactive: 4)), 8);
    });

    test('trop de corrections réactives annule la composante', () async {
      // Quatre corrections subies après alerte : 0 pt, quoi qu'il arrive par
      // ailleurs. Corriger seulement sous alerte ne démontre pas la même
      // autorégulation que se relire de soi-même.
      expect(await score(parfait(reactive: 4)), 8);
    });

    test('à nombre égal, le proactif ne vaut pas moins que le réactif',
        () async {
      final proactif = await score(parfait(proactive: 4));
      final reactif = await score(parfait(reactive: 4));
      expect(proactif, greaterThanOrEqualTo(reactif));
    });
  });

  test('la latence de planification n\'entre pas dans le score', () async {
    // Métrique diagnostique : le référentiel la veut au profil qualitatif, pas
    // au barème.
    final sans = await score(parfait());
    final avec = await score(
      TaskSchedulingMetrics(
        universeId: 'restaurant',
        dependencyEdgeCount: 10,
        dependencyEdgesRespected: 10,
        directDependencyViolations: 0,
        timingConstraintCount: 6,
        timingConstraintsRespected: 6,
        collisionFree: true,
        deadTimeRatio: 0,
        proactiveAdjustments: 0,
        reactiveAdjustments: 0,
        planningLatencyMs: 45000,
      ),
    );
    expect(avec, sans);
  });
}
