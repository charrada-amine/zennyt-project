import 'game_metrics.dart';

/// Metrics for Planifik mini-game #3: Predictive Puzzle.
///
/// The client sends measured planning/execution outcomes only. Scores are
/// replayed by the backend or mock repository.
class PrevisionPuzzleMetrics extends GameMetrics {
  const PrevisionPuzzleMetrics({
    required this.targetCompleted,
    required this.sequenceErrors,
    required this.unnecessaryMoves,
    required this.retries,
    required this.plannedMoves,
    required this.optimalMoves,
  });

  final bool targetCompleted;
  final int sequenceErrors;
  final int unnecessaryMoves;
  final int retries;
  final int plannedMoves;
  final int optimalMoves;

  @override
  Map<String, dynamic> toJson() => {
    'targetCompleted': targetCompleted,
    'sequenceErrors': sequenceErrors,
    'unnecessaryMoves': unnecessaryMoves,
    'retries': retries,
    'plannedMoves': plannedMoves,
    'optimalMoves': optimalMoves,
  };
}
