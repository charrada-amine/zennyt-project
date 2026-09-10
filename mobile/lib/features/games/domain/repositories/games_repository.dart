import '../entities/decision_form.dart';
import '../entities/device_calibration.dart';
import '../entities/emotional_radar.dart';
import '../entities/game_session.dart';
import '../entities/game_type.dart';
import '../entities/game_metrics.dart';
import '../entities/mini_game.dart';

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
  /// [deviceCalibration] est optionnel (socle de calibrage appareil, Tâche 4).
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  });

  /// `GET /games/sessions/{id}/decision/items` — forme « Je Décide » de la session.
  ///
  /// Les 30 items sont servis SANS clé de correction : ni qualité d'option, ni
  /// score, ni réponse attendue. La notation est faite serveur à la soumission,
  /// à partir de la forme persistée sur la session.
  Future<DecisionForm> decisionItems(String sessionId, {String language});

  /// `GET /games/sessions/{id}/emotional-radar/scenes` — matériel de la session.
  ///
  /// Le contenu (texte, image, vidéo) vient du backend : c'est le premier jeu
  /// dont les scènes ne sont pas embarquées dans l'application.
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId);

  /// `POST /games/sessions/{id}/emotional-radar/scenes/{sceneId}/answers`
  ///
  /// Le serveur note la réponse et renvoie la correction. Le client ne connaît
  /// jamais la réponse attendue avant d'avoir validé.
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  });
}
