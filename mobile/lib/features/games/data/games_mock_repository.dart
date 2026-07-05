import '../domain/entities/game_score.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/mini_game.dart';
import '../domain/entities/move_fast_metrics.dart';
import '../domain/entities/planifik_metrics.dart';
import '../domain/entities/prevision_puzzle_metrics.dart';
import '../domain/repositories/games_repository.dart';

/// [GamesRepository] MOCK — permet de jouer en totale autonomie, sans backend.
///
/// Elle maintient l'état des sessions en mémoire et reproduit le barème serveur
/// (fiche « Je planifie ») pour renvoyer un score cohérent. Le jour de
/// l'intégration, on remplace cette source par [GamesRepositoryImpl] dans
/// `games_providers.dart` — rien d'autre ne change (ni contrôleur, ni Flame).
class GamesMockRepository implements GamesRepository {
  final Map<String, GameSession> _sessions = {};
  int _counter = 0;

  @override
  Future<GameSession> startSession(GameType gameType) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 150),
    ); // simule le réseau
    final id = 'mock-session-${++_counter}';
    final session = GameSession(
      id: id,
      gameType: gameType,
      status: 'IN_PROGRESS',
      compositeRaw: 0,
      compositeMax: gameType == GameType.moveFast ? 0 : 30,
      normalized: 0,
      attempts: const [],
      startedAt: DateTime.now(),
    );
    _sessions[id] = session;
    return session;
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _sessions[sessionId];
    if (current == null) {
      throw StateError('Session mock introuvable : $sessionId');
    }

    final score = switch (miniGame) {
      MiniGame.optimalPath => _scoreOptimalPath(metrics as PlanifikMetrics),
      MiniGame.previsionPuzzle => _scorePrevisionPuzzle(
        metrics as PrevisionPuzzleMetrics,
      ),
      MiniGame.moveFastCore => _scoreMoveFast(metrics as MoveFastMetrics),
      MiniGame.taskScheduling => throw StateError(
        'Barème mock non implémenté pour ${miniGame.wire}',
      ),
    };
    final attempts = [
      ...current.attempts,
      GameAttempt(miniGame: miniGame, score: score, recordedAt: DateTime.now()),
    ];
    final raw = attempts.fold<int>(0, (sum, a) => sum + a.score.rawPoints);
    final complete =
        miniGame == MiniGame.moveFastCore ||
        attempts.length >= _expectedMiniGames(current.gameType);
    final max = complete
        ? attempts.fold<int>(0, (sum, a) => sum + a.score.maxPoints)
        : current.compositeMax;

    final updated = GameSession(
      id: current.id,
      gameType: current.gameType,
      status: complete ? 'COMPLETED' : current.status,
      compositeRaw: raw,
      compositeMax: max,
      normalized: max == 0 ? 0 : raw * 100.0 / max,
      attempts: attempts,
      startedAt: current.startedAt,
      completedAt: complete ? DateTime.now() : current.completedAt,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Barème « Chemin Optimal » (sur 10) — identique au PlanifikScoringService backend.
  GameScore _scoreOptimalPath(PlanifikMetrics m) {
    var points = 0;
    final deviation = (m.pathLength - m.optimalLength).abs() / m.optimalLength;
    if (deviation <= 0.10) points += 4;
    points += switch (m.attempts) {
      1 => 3,
      2 => 2,
      _ => 1,
    };
    if (m.costlyZonesAvoided) points += 2;
    if (m.secondaryObjectives > 0) points += 1;

    final level = points <= 3
        ? 'Très faible'
        : points <= 6
        ? 'Moyen'
        : 'Bon à excellent';
    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: level,
    );
  }

  GameScore _scoreMoveFast(MoveFastMetrics m) {
    final points = _replayMoveFastScore(m.correctResponses);
    final maxPoints = _replayMoveFastScore(
      List<bool>.filled(m.correctResponses.length, true),
    );
    final normalized = points * 100.0 / maxPoints;
    final level = normalized < 40
        ? 'Très faible'
        : normalized < 60
        ? 'Moyen faible'
        : normalized < 75
        ? 'Moyen'
        : normalized < 90
        ? 'Bon'
        : 'Excellent';

    return GameScore(
      rawPoints: points,
      maxPoints: maxPoints,
      normalized: normalized,
      level: level,
    );
  }

  GameScore _scorePrevisionPuzzle(PrevisionPuzzleMetrics m) {
    var points = m.targetCompleted ? 10 : 4;
    points -= m.sequenceErrors * 2;
    points -= m.unnecessaryMoves;
    points -= m.retries;
    points = points.clamp(0, 10).toInt();

    final level = points <= 3
        ? 'Très faible'
        : points <= 6
        ? 'Moyen'
        : 'Bon à excellent';

    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: level,
    );
  }

  int _replayMoveFastScore(Iterable<bool> responses) {
    var points = 0;
    var multiplier = 1;
    var streakCounter = 0;

    for (final correct in responses) {
      if (correct) {
        points += 50 * multiplier;
        streakCounter++;
        if (streakCounter == 4) {
          streakCounter = 0;
          multiplier = (multiplier + 1).clamp(1, 10).toInt();
        }
      } else if (streakCounter > 0) {
        streakCounter = 0;
      } else {
        multiplier = (multiplier - 1).clamp(1, 10).toInt();
      }
    }

    return points + (250 * multiplier);
  }

  int _expectedMiniGames(GameType gameType) {
    return switch (gameType) {
      GameType.planifik => 3,
      GameType.moveFast => 1,
      GameType.memoryQuest || GameType.decision => 0,
    };
  }
}
