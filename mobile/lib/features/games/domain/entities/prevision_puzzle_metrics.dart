import 'game_metrics.dart';

/// Métriques objectives d'UN niveau de « Predictive Puzzle » (Tour de Hanoï).
///
/// Aligné sur PrevisionPuzzleLevel du contrat games.openapi.yaml. L'optimal est
/// déterministe (2^discCount − 1) ; le backend le recalcule et le valide.
class PrevisionPuzzleLevelMetrics {
  const PrevisionPuzzleLevelMetrics({
    required this.levelIndex,
    required this.discCount,
    required this.firstTrySuccess,
    required this.sequenceErrors,
    required this.plannedMoves,
    required this.optimalMoves,
    required this.retries,
    required this.completed,
  });

  final int levelIndex;
  final int discCount;
  final bool firstTrySuccess;
  final int sequenceErrors;
  final int plannedMoves;
  final int optimalMoves;
  final int retries;
  final bool completed;

  Map<String, dynamic> toJson() => {
    'levelIndex': levelIndex,
    'discCount': discCount,
    'firstTrySuccess': firstTrySuccess,
    'sequenceErrors': sequenceErrors,
    'plannedMoves': plannedMoves,
    'optimalMoves': optimalMoves,
    'retries': retries,
    'completed': completed,
  };
}

/// Metrics for Planifik mini-game #3: Predictive Puzzle.
///
/// Le mini-jeu enchaîne plusieurs niveaux : les métriques portent la liste
/// [levels]. Le serveur note chaque niveau /10 (barème catégoriel de la fiche)
/// puis agrège par moyenne arrondie (un seul Attempt). Aligné sur
/// PrevisionPuzzleMetrics du contrat.
class PrevisionPuzzleMetrics extends GameMetrics {
  const PrevisionPuzzleMetrics({required this.levels});

  final List<PrevisionPuzzleLevelMetrics> levels;

  @override
  Map<String, dynamic> toJson() => {
    'levels': levels.map((l) => l.toJson()).toList(),
  };
}
