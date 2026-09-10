import '../entities/emotional_radar_v2.dart';

/// Contract dedicated to the adaptive Emotional Radar v2 flow.
///
/// It remains separate from [GamesRepository] while v1 compatibility is kept:
/// existing games test doubles do not need to implement endpoints they never
/// call. Both the Dio and offline/mock repositories implement this contract.
abstract interface class EmotionalRadarV2Repository {
  /// Returns a pure server-owned snapshot and never starts a scene timer.
  Future<EmotionalRadarV2State> emotionalRadarV2State(String sessionId);

  /// Idempotently creates/returns the next pending scene and starts its
  /// server-side response budget. This is the only scene activation operation.
  Future<EmotionalRadarV2State> activateNextEmotionalRadarV2Scene(
    String sessionId,
  );

  /// Submits only the player's observations. Timing, correction, difficulty,
  /// report and score are calculated by the backend/repository authority. A
  /// non-final response intentionally has no current scene; the caller activates
  /// it only when leaving feedback.
  Future<EmotionalRadarV2AnswerResult> answerEmotionalRadarV2Scene({
    required String sessionId,
    required int sceneOrder,
    required String selectedEmotionKey,
    required EmotionalRadarV2Intensity selectedIntensity,
    required String explanation,
  });
}
