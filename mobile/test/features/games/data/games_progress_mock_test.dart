import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/reflective_pause_config.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/games_progress.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_metrics.dart';

void main() {
  test(
    'hors ligne, une partie enregistrée fait monter la couverture',
    () async {
      final repo = GamesMockRepository();
      expect((await repo.gamesProgress()).coveragePercent, 0);

      final session = await repo.startSession(GameType.emotionalRegulation);
      await repo.submitResult(
        sessionId: session.id,
        miniGame: MiniGame.reflectivePauseCore,
        metrics: ReflectivePauseMetrics(
        moments: [
          for (var i = 0; i < ReflectivePauseConfig.totalMoments; i++)
            ReflectivePauseMomentMetric(
              momentId: 'TR-${(i + 1).toString().padLeft(3, '0')}',
              selectedResponse: ReflectivePauseResponseType.breatheAnalyze,
              responseTimeMs: 4000,
              minimumTimerReached: true,
            ),
        ],
      ),
      );

      final progress = await repo.gamesProgress();
      expect(progress.completed, {CatalogGame.reflectivePause});
      expect(progress.coveragePercent, 7, reason: '1 / 15');
    },
  );
}
