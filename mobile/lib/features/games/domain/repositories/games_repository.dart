import '../entities/game_session.dart';
import '../entities/game_type.dart';
import '../entities/mini_game.dart';
import '../entities/planifik_metrics.dart';

/// Abstraction sur les sessions de jeux sérieux. La présentation dépend
/// uniquement de cette interface.
///
/// Les implémentations lèvent des `ApiException` typées en cas d'échec. C'est
/// ce qui permet de brancher indifféremment la source distante (backend) ou la
/// source mock (jeu autonome, sans backend).
abstract class GamesRepository {
  /// `POST /games/sessions` — démarre une session pour le joueur connecté.
  Future<GameSession> startSession(GameType gameType);

  /// `POST /games/sessions/{id}/results` — soumet les métriques d'un mini-jeu.
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required PlanifikMetrics metrics,
  });
}
