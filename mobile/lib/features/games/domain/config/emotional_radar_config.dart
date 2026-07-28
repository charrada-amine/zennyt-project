import '../entities/emotional_radar.dart';

/// Barème « Emotional Radar » — **miroir Dart** de
/// `backend/.../domain/config/EmotionalRadarConfig.java`.
///
/// ⚠️ PARITÉ MOCK ⇄ BACKEND (AGENTS.md §7.7) : toute modification ici impose la
/// même modification côté Java, dans la même PR. Rien n'est codé en dur dans
/// l'écran ni dans le mock — les deux lisent ces constantes.
class EmotionalRadarConfig {
  EmotionalRadarConfig._();

  /// `basic_emotion` — famille exacte, tout ou rien.
  static const int emotionPoints = 3;

  /// `nuance` — nuance exacte, tout ou rien.
  static const int nuancePoints = 4;

  /// `intensity` — maximum du critère d'intensité.
  static const int intensityPoints = 2;

  /// Total par scène sans bonus : 3 + 4 + 2 = 9.
  static const int pointsPerScene = emotionPoints + nuancePoints + intensityPoints;

  /// `gradient_bonus` — « +1 optional » sur la maquette.
  ///
  /// ⚠️ DÉSACTIVÉ par défaut : l'activer porterait une scène à 10 points et
  /// contredirait les deux totaux de la maquette (27 pour 3 scènes, 135 pour 15).
  static const bool gradientBonusEnabled = false;
  static const int gradientBonusPoints = 1;

  static const int minIntensity = 1;
  static const int maxIntensity = 5;

  /// Libellés des 5 niveaux (maquette : Weak → Very strong).
  static const List<String> intensityLabels = [
    'Weak',
    'Low',
    'Moderate',
    'Strong',
    'Very strong',
  ];

  /// Libellé du niveau `level` (1–5).
  static String intensityLabel(int level) =>
      intensityLabels[(level - 1).clamp(0, intensityLabels.length - 1)];

  /// Points du critère d'intensité selon l'écart à l'intensité attendue.
  /// Écart 0 → 2 pts · écart 1 → 1 pt · écart ≥ 2 → 0.
  static int intensityScore(int expected, int selected) {
    final gap = (expected - selected).abs();
    if (gap == 0) return intensityPoints;
    if (gap == 1) return 1;
    return 0;
  }

  /// Maximum pour un nombre de scènes jouées (barème dynamique).
  static int maxPointsFor(int scenesPlayed) {
    final perScene = pointsPerScene + (gradientBonusEnabled ? gradientBonusPoints : 0);
    return (scenesPlayed < 1 ? 1 : scenesPlayed) * perScene;
  }

  /// Bandes d'interprétation (/100).
  /// ⚠️ PROVISOIRE — aucune fiche ne les fournit ; alignées sur les autres jeux.
  static String interpret(double normalized) {
    if (normalized < 40) return 'Très faible';
    if (normalized < 60) return 'Moyen faible';
    if (normalized < 75) return 'Moyen';
    if (normalized < 90) return 'Bon';
    return 'Excellent';
  }

  /// Les 6 familles, dans l'ordre de la grille 2×3 de la maquette.
  static const List<BasicEmotion> emotionGridOrder = [
    BasicEmotion.joy,
    BasicEmotion.sadness,
    BasicEmotion.anger,
    BasicEmotion.fear,
    BasicEmotion.disgust,
    BasicEmotion.surprise,
  ];
}
