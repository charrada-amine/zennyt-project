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

  /// Les seules vidéos réellement produites : 3 des 135 attendues. PROVISOIRE.
  ///
  /// Miroir de `EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE` côté backend —
  /// la parité mock/serveur est ce qui permet de jouer hors ligne sans que le
  /// jeu se comporte différemment.
  ///
  /// Le rattachement se fait par ÉMOTION, jamais par ordre de scène : un clip
  /// posé sur « la scène 1 » montrerait une femme inquiète alors que la réponse
  /// attendue serait « Joie ». La vidéo contredirait la correction — pire qu'un
  /// placeholder. Ce choix appartient à l'autorité de correction, pas à l'UI,
  /// qui ignore la cible et doit continuer à l'ignorer.
  static const Map<String, RadarDemoFootage> demoFootage = {
    'SADNESS': RadarDemoFootage(
      'assets/games_demo/emotional_radar/phone_call.mp4',
    ),
    'ANXIETY': RadarDemoFootage(
      'assets/games_demo/emotional_radar/night_apartment.mp4',
    ),
    // Stimulus contextuel : le référentiel exige une légende. Factuelle, sans
    // mot d'émotion — « aucun texte ne doit révéler l'émotion à identifier ».
    'LONELINESS': RadarDemoFootage(
      'assets/games_demo/emotional_radar/park_bench.mp4',
      contextualCaption: 'Un parc, en fin de journée.',
    ),
  };

  // Bandes d'interprétation (/100). PROVISOIRE.
  static String interpret(double normalized) {
    if (normalized < 40) return 'Très faible';
    if (normalized < 60) return 'Moyen faible';
    if (normalized < 75) return 'Moyen';
    if (normalized < 90) return 'Bon';
    return 'Excellent';
  }
}

/// Un clip de démonstration : son chemin embarqué, et sa légende si le stimulus
/// l'exige.
class RadarDemoFootage {
  const RadarDemoFootage(this.mediaUrl, {this.contextualCaption});

  final String mediaUrl;
  final String? contextualCaption;
}
