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

  // ── Mode FIXED_BUDGET — miroir de SESSION_END_CONDITION (12 / 18 / 84 s) ────
  static const int targetCorrectAnswers = 12;
  static const int maxResponses = 18;
  static const int sessionSeconds = 84;

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
