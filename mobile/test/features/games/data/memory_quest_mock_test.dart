import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/device_calibration.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/memory_quest_metrics.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

/// Parité mock ⇄ backend « J'investigue » : composite + timeout ajusté du calibrage.
void main() {
  Future<int> composite(
    MemoryQuestMetrics m, {
    DeviceCalibration? calibration,
  }) async {
    final repo = GamesMockRepository();
    final session = await repo.startSession(GameType.memoryQuest);
    final updated = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.memoryQuestCore,
      metrics: m,
      deviceCalibration: calibration,
    );
    return updated.lastAttempt!.score.rawPoints;
  }

  // Calibrage à fort offset : refreshRate bas + latence d'entrée élevée.
  DeviceCalibration slowDevice() => const DeviceCalibration(
        calibrationMethod: CalibrationMethod.technique,
        inputMode: InputMode.touch,
        deviceCategory: DeviceCategory.mobile,
        refreshRateHz: 60,
        inputProcessingLatencyMs: 2000,
      );

  test('non-régression : composite agrégat (sans tasks) inchangé', () async {
    // same 4/4→5, reverse 3/4→4, restore 4/4→5, after-distr 4/4→5 → 95.
    const m = MemoryQuestMetrics(
      observedDigits: 4,
      correctSameDigits: 4,
      correctReverseDigits: 3,
      highestSequenceLength: 5,
      objectCount: 4,
      restoreCorrect: 4,
      manipulationCount: 2,
      distractionPlayed: true,
      afterDistractionObserved: 4,
      afterDistractionCorrect: 4,
      distractionQuestionCorrect: true,
    );
    expect(await composite(m), 95);
  });

  test('timeout voide la note sauf si le calibrage remonte le seuil', () async {
    // Une tâche parfaite mais trop lente d'1 ms.
    final m = MemoryQuestMetrics(
      observedDigits: 4,
      correctSameDigits: 4,
      correctReverseDigits: 4,
      highestSequenceLength: 4,
      finalLevel: 1,
      tasks: [
        MemoryTaskResult(
          kind: MemoryTaskKind.sameOrder,
          correct: 4,
          total: 4,
          responseTimeMs: MemoryQuestConfig.maxTaskTimeMs + 1,
        ),
      ],
    );
    // Sans calibrage : dépassement → note voidée → composite 0.
    expect(await composite(m), 0);
    // Appareil lent (offset ≈ 2008 ms) : seuil remonté → note conservée → 100.
    expect(await composite(m, calibration: slowDevice()), 100);
  });
}
