import 'game_metrics.dart';

/// Raw metrics for « Je bouge / Move Fast ».
///
/// The backend replays [correctResponses] to calculate the escalation score.
class MoveFastMetrics extends GameMetrics {
  const MoveFastMetrics({
    required this.correctResponses,
    required this.reactionTimesMs,
  });

  final List<bool> correctResponses;
  final List<int> reactionTimesMs;

  @override
  Map<String, dynamic> toJson() => {
    'correctResponses': correctResponses,
    'reactionTimesMs': reactionTimesMs,
  };
}
