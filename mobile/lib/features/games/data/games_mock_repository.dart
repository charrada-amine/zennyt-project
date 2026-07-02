import '../domain/entities/game_score.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/mini_game.dart';
import '../domain/entities/planifik_metrics.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 150)); // simule le réseau
    final id = 'mock-session-${++_counter}';
    final session = GameSession(
      id: id,
      gameType: gameType,
      status: 'IN_PROGRESS',
      compositeRaw: 0,
      compositeMax: 30,
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
    required PlanifikMetrics metrics,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _sessions[sessionId];
    if (current == null) {
      throw StateError('Session mock introuvable : $sessionId');
    }

    final score = _scoreOptimalPath(metrics);
    final attempts = [
      ...current.attempts,
      GameAttempt(miniGame: miniGame, score: score, recordedAt: DateTime.now()),
    ];
    final raw = attempts.fold<int>(0, (sum, a) => sum + a.score.rawPoints);

    final updated = GameSession(
      id: current.id,
      gameType: current.gameType,
      status: current.status,
      compositeRaw: raw,
      compositeMax: current.compositeMax,
      normalized: raw * 100.0 / current.compositeMax,
      attempts: attempts,
      startedAt: current.startedAt,
      completedAt: current.completedAt,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Barème « Chemin Optimal » (sur 10) — identique au PlanifikScoringService backend.
  GameScore _scoreOptimalPath(PlanifikMetrics m) {
    var points = 0;
    final deviation = (m.pathLength - m.optimalLength).abs() / m.optimalLength;
    if (deviation <= 0.10) points += 4;
    points += switch (m.attempts) { 1 => 3, 2 => 2, _ => 1 };
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
}
