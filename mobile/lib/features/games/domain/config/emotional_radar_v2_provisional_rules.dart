/// Miroir Dart de `EmotionalRadarV2ProvisionalRules` (backend). Couche PROVISOIRE :
/// chaque constante est marquée PROVISOIRE et doit rester alignée avec le backend.
library;

class EmotionalRadarV2ProvisionalRules {
  EmotionalRadarV2ProvisionalRules._();

  // Score « jeu » (radar_emotion_score /10). PROVISOIRE.
  static const double gameScoreLevelWeight = 0.7;
  static const double gameScoreAccuracyWeight = 0.3;
  static const double emotionalLevelHighMin = 7.0;
  static const double emotionalLevelMediumMin = 4.0;

  static String emotionalLevel(double gameScore) {
    if (gameScore >= emotionalLevelHighMin) return 'Élevé';
    if (gameScore >= emotionalLevelMediumMin) return 'Moyen';
    return 'Faible';
  }

  // Couche décisionnelle theta — VERROUILLÉE (calculée côté serveur uniquement).
  // Le mobile n'estime jamais theta : il ne doit pas exposer d'usage décisionnel.
  static const bool decisionalUseAllowed = false; // PROVISOIRE — NE PAS activer
  static const int minItemsForReliableTheta = 20;

  // Bandes d'interprétation (/100). PROVISOIRE.
  static String interpret(double normalized) {
    if (normalized < 40) return 'Très faible';
    if (normalized < 60) return 'Moyen faible';
    if (normalized < 75) return 'Moyen';
    if (normalized < 90) return 'Bon';
    return 'Excellent';
  }
}
