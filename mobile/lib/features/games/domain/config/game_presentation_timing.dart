import '../entities/game_runtime_snapshot.dart';

/// Presentation policy, never a scoring input. Defaults/bounds mirror backend
/// AdminConfigurationSchemaRegistry. Old snapshots and mocks keep old timings.
/// PROVISOIRE — configurable bounds requested by product, pending psych review.
class GamePresentationTiming {
  const GamePresentationTiming(this.runtime);
  final GameRuntimeSnapshot runtime;

  int _ms(String key, int fallback, int minimum, int maximum) => runtime
      .settingInt(key, fallback: fallback, minimum: minimum, maximum: maximum);

  int get memoryDigitVisibleMs => _ms('memoryDigitVisibleMs', 900, 300, 3000);
  int get memoryDigitGapMs => _ms('memoryDigitGapMs', 1000, 200, 3000);
  int get memoryManipulationStepMs =>
      _ms('memoryManipulationStepMs', 750, 200, 3000);
  int get memoryRetentionMs => _ms('memoryRetentionMs', 3000, 0, 10000);
  int get puzzlePlaybackStepMs => _ms('puzzlePlaybackStepMs', 420, 150, 2000);
  int get responseFeedbackMs => _ms('responseFeedbackMs', 650, 200, 2000);
  int get reflectiveThinkingTimeMs =>
      _ms('reflectiveThinkingTimeMs', 3000, 3000, 15000);
  int get reflectiveTransitionMs => _ms('reflectiveTransitionMs', 700, 0, 5000);
}
