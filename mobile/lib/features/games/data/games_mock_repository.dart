import '../domain/entities/device_calibration.dart';
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
///
/// ⚠️ PARITÉ MOCK ⇄ BACKEND. Les méthodes `_scoreOptimalPath` / `_scoreMoveFast`
/// / `_scorePrevisionPuzzle` sont le MIROIR EXACT du barème serveur
/// `backend/.../games/domain/service/PlanifikScoringService.java`
/// (+ constantes `MoveFastConfig` / `OptimalPathConfig` / `PrevisionPuzzleConfig`).
/// Toute modification de barème DOIT être répercutée dans les deux fichiers
/// DANS LA MÊME PR.
class GamesMockRepository implements GamesRepository {
  final Map<String, GameSession> _sessions = {};
  int _counter = 0;

  // Config « Chemin Optimal » — miroir de OptimalPathConfig (backend).
  static const double _optimalPathTolerance = 0.10; // optimal_path_tolerance
  static const int _maxAttempts = 3; // max_attempts

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
    // Accepté pour parité d'interface ; le mock ne calcule pas d'indicateurs
    // corrigés (le calibrage n'affecte pas le score).
    DeviceCalibration? deviceCalibration,
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
  ///
  /// Chaque niveau est noté /10 puis agrégé par MOYENNE ARRONDIE (un seul Attempt
  /// par mini-jeu). ⚠️ Agrégation par moyenne à valider avec le psychologue.
  GameScore _scoreOptimalPath(PlanifikMetrics m) {
    final total = m.levels.fold<int>(0, (sum, l) => sum + _scoreOptimalPathLevel(l));
    final average = m.levels.isEmpty ? 0.0 : total / m.levels.length;
    final points = average.round().clamp(0, 10).toInt();

    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: _interpretMiniGame(points),
    );
  }

  /// Note un niveau /10 selon le barème de la fiche (miroir du backend).
  int _scoreOptimalPathLevel(PlanifikLevelMetrics l) {
    var points = 0;
    final deviation = (l.pathLength - l.optimalLength).abs() / l.optimalLength;
    if (deviation <= _optimalPathTolerance) points += 4;
    points += _attemptScore(l.attempts);
    points += switch (l.costlyZonesAvoided) {
      CostlyZonesAvoided.total => 2,
      CostlyZonesAvoided.partial => 1, // raffinement à valider
      CostlyZonesAvoided.none => 0,
    };
    points += switch (l.secondaryObjectivesReached) {
      SecondaryObjectivesReached.yes => 1,
      SecondaryObjectivesReached.partial => 0, // règle à valider
      SecondaryObjectivesReached.no => 0,
    };
    return points;
  }

  /// Bandes /10 par mini-jeu (0–3 / 4–6 / 7–10) — provisoires, non validées.
  String _interpretMiniGame(int points) {
    if (points <= 3) return 'Très faible';
    if (points <= 6) return 'Moyen';
    return 'Bon à excellent';
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

  /// Barème CATÉGORIEL « Predictive Puzzle » — miroir EXACT du backend
  /// (PrevisionPuzzleConfig). Chaque niveau /10, puis moyenne arrondie.
  GameScore _scorePrevisionPuzzle(PrevisionPuzzleMetrics m) {
    final total = m.levels.fold<int>(0, (sum, l) => sum + _scorePuzzleLevel(l));
    final average = m.levels.isEmpty ? 0.0 : total / m.levels.length;
    final points = average.round().clamp(0, 10).toInt();

    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: _interpretMiniGame(points),
    );
  }

  /// Score /10 d'un niveau : 1er essai + erreurs de séquence + coups superflus.
  int _scorePuzzleLevel(PrevisionPuzzleLevelMetrics l) {
    final firstTry = l.firstTrySuccess ? 4 : 0;
    final seqErrors = l.sequenceErrors == 0
        ? 3
        : l.sequenceErrors <= 2
        ? 2
        : 1;
    final ratio = l.optimalMoves <= 0
        ? 0.0
        : (l.plannedMoves - l.optimalMoves) / l.optimalMoves;
    final extra = ratio < 0.10
        ? 3
        : ratio < 0.25
        ? 2
        : 1;
    return firstTry + seqErrors + extra;
  }

  /// Points « nombre d'essais » — miroir de OptimalPathConfig.attemptScore :
  /// 1 essai = _maxAttempts pts, −1 par essai supplémentaire, plancher 1.
  int _attemptScore(int attempts) {
    final capped = attempts < _maxAttempts ? attempts : _maxAttempts;
    final points = _maxAttempts + 1 - capped;
    return points < 1 ? 1 : points;
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
      // Transitoire : TASK_SCHEDULING n'est pas jouable (barème non implémenté),
      // il est exclu de la complétion — miroir du backend (MiniGame.isPlayable()).
      // Planifik se complète donc sur OPTIMAL_PATH + PREVISION_PUZZLE.
      GameType.planifik => 2,
      GameType.moveFast => 1,
      GameType.memoryQuest || GameType.decision => 0,
    };
  }
}
