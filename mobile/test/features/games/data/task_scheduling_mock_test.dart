import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/task_scheduling_metrics.dart';

/// Parité mock ⇄ backend du barème « Ordonnancement de tâches » (Planifik #2).
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

  test('planning parfait = 10/10', () async {
    expect(
      await score(const TaskSchedulingMetrics(
        dependenciesRespected: true,
        timeConstraintsRespected: true,
        planningCoherence: 2,
        adjustmentCount: 0,
      )),
      10,
    );
  });

  test('2 réajustements → 1 pt (tranche 2-4, pas 2) → 3+3+0+1 = 7', () async {
    expect(
      await score(const TaskSchedulingMetrics(
        dependenciesRespected: true,
        timeConstraintsRespected: true,
        planningCoherence: 0,
        adjustmentCount: 2,
      )),
      7,
    );
  });

  test('dépendances non respectées → 0 sur ce critère → 0+3+2+2 = 7', () async {
    expect(
      await score(const TaskSchedulingMetrics(
        dependenciesRespected: false,
        timeConstraintsRespected: true,
        planningCoherence: 2,
        adjustmentCount: 0,
      )),
      7,
    );
  });

  test('>4 réajustements → 0 pt → 3+3+2+0 = 8', () async {
    expect(
      await score(const TaskSchedulingMetrics(
        dependenciesRespected: true,
        timeConstraintsRespected: true,
        planningCoherence: 2,
        adjustmentCount: 5,
      )),
      8,
    );
  });
}
