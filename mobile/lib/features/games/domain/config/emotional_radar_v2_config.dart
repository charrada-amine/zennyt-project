/// Miroir Dart de `EmotionalRadarV2Config` (backend) — « Emotional Radar v2 ».
///
/// Toute modification ici impose la même modification côté backend (AGENTS.md §7.7).
/// Table de configuration admin du brief (2026-08-12, niveaux de choix 6/6/9/9).
library;

/// Bande de proximité sémantique visée par un niveau (valeurs PROVISOIRES).
enum DistanceBand {
  high(0.70), // émotions très différentes (facile)
  medium(0.45),
  low(0.22); // émotions très proches (difficile)

  const DistanceBand(this.target);
  final double target;
}

/// Un niveau à deux axes : nombre de choix (charge) + distance visée (finesse).
class DifficultyLevel {
  const DifficultyLevel(this.level, this.choicesCount, this.targetDistance);
  final int level;
  final int choicesCount;
  final DistanceBand targetDistance;
}

class EmotionalRadarV2Config {
  EmotionalRadarV2Config._();

  static const int emotionPoolSize = 45;
  static const int totalScenes = 15;
  static const int videoLibrarySize = 135; // 45 × 3 intensités
  static const List<String> stimulusIntensityLevels = ['Faible', 'Modérée', 'Intense'];
  static const List<String> intensityScale = stimulusIntensityLevels;

  static const int difficultyLevels = 4;

  /// 6 / 6 / 9 / 9 + distance Élevée / Moyenne / Élevée / Faible.
  static const List<DifficultyLevel> levels = [
    DifficultyLevel(1, 6, DistanceBand.high),
    DifficultyLevel(2, 6, DistanceBand.medium),
    DifficultyLevel(3, 9, DistanceBand.high), // charge cognitive isolée
    DifficultyLevel(4, 9, DistanceBand.low), // charge + finesse combinées
  ];

  static const double levelUpThreshold = 0.70;
  static const double levelDownThreshold = 0.40;
  static const int evaluationWindowMin = 3;
  static const int evaluationWindowMax = 4;
  static const int startingLevel = 1;

  static const int maxResponseTimeMs = 8000;
  static const int minImpulsiveTimeMs = 400;

  static const bool normingRequiredBeforeUse = true;
  static const bool requireExplanation = true;
  static const int justificationMinScore = 0;
  static const int justificationMaxScore = 5;

  static DifficultyLevel level(int levelNumber) => levels[levelNumber - 1];
  static int choicesForLevel(int levelNumber) => level(levelNumber).choicesCount;
}
