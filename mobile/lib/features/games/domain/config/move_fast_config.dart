// Miroir Dart de `MoveFastConfig` (backend) — source UNIQUE côté mobile pour la
// condition de fin de session et les bandes d'interprétation. L'écran et le mock
// lisent ces valeurs (rien n'est codé en dur ailleurs) pour rester alignés
// backend ⇄ mock.

/// Mode de fin de session Move Fast (miroir de `MoveFastConfig.SessionEndMode`).
enum MoveFastSessionEndMode {
  /// Comportement ACTUEL du produit : budget fixe (12 bonnes / 18 essais / 84 s).
  /// ⚠️ DIVERGE de la fiche mais reste le mode par défaut.
  fixedBudget,

  /// Règle de la FICHE « JE BOUGE » : jouer jusqu'au multiplicateur max (×10),
  /// sans limite de temps ni d'essais.
  reachMaxMultiplier,
}

/// Configuration « Je bouge / Move Fast » côté mobile.
class MoveFastConfig {
  MoveFastConfig._();

  /// Mode de fin de session par défaut.
  ///
  /// ⚠️ DIVERGENCE ASSUMÉE : [MoveFastSessionEndMode.fixedBudget] est le
  /// comportement du produit et **diverge de la fiche** (qui prescrit
  /// `reach_max_multiplier`). Basculer = changer **uniquement cette constante**
  /// (+ son pendant backend `MoveFastConfig.SESSION_END_MODE`). En attente
  /// d'arbitrage du psychologue référent — ne pas trancher sans lui.
  static const MoveFastSessionEndMode sessionEndMode =
      MoveFastSessionEndMode.fixedBudget;

  // ── Mode FIXED_BUDGET — miroir de SESSION_END_CONDITION (40 / 60 / 600 s) ───
  //
  // ⚠️ Ces trois valeurs se tiennent ensemble. Le multiplicateur monte d'un cran
  // toutes les 4 bonnes réponses consécutives : atteindre [maxMultiplier] (10)
  // depuis 1 demande 9 montées, donc 9 × 4 = 36 bonnes réponses AU MINIMUM.
  // Avec l'ancien targetCorrectAnswers = 12, la session s'arrêtait après
  // 3 montées et le multiplicateur plafonnait mécaniquement à ×4 — le maximum
  // déclaré était inatteignable. Garder targetCorrectAnswers > 36.
  /// Bonnes réponses consécutives pour faire monter le multiplicateur d'un cran
  /// — miroir de `MoveFastConfig.CORRECT_STREAK_FOR_UPGRADE` (backend).
  static const int correctStreakForUpgrade = 4;

  static const int targetCorrectAnswers = 40;
  static const int maxResponses = 60;

  /// Budget de temps : 10 minutes. L'ancien budget de 84 s ne laissait pas le
  /// temps de jouer 36 essais corrects, seconde raison du plafond à ×4.
  static const int sessionSeconds = 600;

  /// Plafond du multiplicateur — condition de fin en mode REACH_MAX_MULTIPLIER
  /// (cœur du barème, miroir de `MAX_MULTIPLIER`, NE PAS modifier).
  static const int maxMultiplier = 10;

  /// Essais d'échauffement (warm-up) — miroir de `PRACTICE_TRIAL_COUNT`.
  static const int practiceTrialCount = 3;

  /// Bandes d'interprétation du score normalisé (/100).
  ///
  /// // AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE — bandes provisoires.
  /// Source UNIQUE côté mobile (miroir de `MoveFastConfig.INTERPRETATION_BANDS`
  /// backend). Ne pas dupliquer ces seuils ailleurs.
  static String interpretMoveFast(double normalized) {
    if (normalized < 40) return 'Très faible';
    if (normalized < 60) return 'Moyen faible';
    if (normalized < 75) return 'Moyen';
    if (normalized < 90) return 'Bon';
    return 'Excellent';
  }
}
