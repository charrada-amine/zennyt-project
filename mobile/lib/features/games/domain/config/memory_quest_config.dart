// Miroir Dart de `MemoryQuestConfig` (backend) — source UNIQUE côté mobile pour
// le système de niveaux, le timeout par tâche (calibrage) et la validité de
// session. L'écran et le mock lisent ces valeurs pour rester alignés backend ⇄ mock.

/// Configuration « J'investigue » (mémoire de travail) côté mobile.
class MemoryQuestConfig {
  MemoryQuestConfig._();

  static const int taskMaxScore = 5;
  static const int compositeMax = 100;

  // ── Système de niveaux (fiche Tableau 1) ──────────────────────────────────
  static const int initialSequenceLength = 3;
  static const int sequenceIncrement = 1;
  static const int maxSequenceLength = 9;
  static const int totalLevels = 7; // longueurs 3..9
  static const int correctTasksForLevelUp = 3;

  /// Un seul tour par niveau : après chaque tour on incrémente le niveau
  /// (séquence plus longue + plus d'objets), jusqu'au dernier niveau.
  static const int roundsPerLevel = 1;

  /// Budget d'erreurs sur TOUTE la partie (toutes tâches, tous niveaux
  /// confondus) : le joueur peut se tromper jusqu'à [maxMistakes] fois ; au-delà,
  /// la partie s'arrête et l'écran de score s'affiche. Une « erreur » = une tâche
  /// de rappel/restauration non parfaite (chiffres, inverse, objets, après
  /// distraction).
  static const int maxMistakes = 3;
  static const bool resetSequenceOnError = true;
  static const int minObjectCount = 4;
  static const int maxObjectCount = 12;
  static const int distractionMinLevel = 3; // gating : niveaux 1-2 sans distraction
  static const bool hintsEnabled = false;
  static const bool partialCreditEnabled = true;
  static const int maxSessionDurationMin = 30;

  /// Longueur de séquence à un niveau (1-based) : 3 + (level-1), plafonnée à 9.
  static int sequenceLengthForLevel(int level) {
    final len = initialSequenceLength + (level.clamp(1, 1 << 30) - 1) * sequenceIncrement;
    return len < maxSequenceLength ? len : maxSequenceLength;
  }

  /// Nombre d'objets (Mission B) à un niveau : 4 (niveau 1) → 12 (dernier niveau).
  static int objectCountForLevel(int level) {
    final clamped = level.clamp(1, totalLevels);
    if (totalLevels <= 1) return minObjectCount;
    final span = maxObjectCount - minObjectCount;
    return minObjectCount + (span * (clamped - 1) / (totalLevels - 1)).round();
  }

  /// Distraction gatée : active à partir du niveau 3.
  static bool distractionActiveAtLevel(int level) => level >= distractionMinLevel;

  // ── Temps d'observation des objets (Mission B) ─────────────────────────────
  /// Temps de mémorisation par objet (ms). Calé sur les 5 s initiales du plus
  /// petit lot (5000 / 4 objets ≈ 1250 ms) : le temps de réflexion croît donc
  /// proportionnellement au nombre d'objets à mémoriser.
  static const int objectObservationMsPerItem = 1250;

  /// Plancher du temps d'observation des objets (identique à l'ancien 5 s fixe).
  static const int objectObservationMinMs = 5000;

  /// Temps d'observation des objets à un niveau : ~1.25 s × nombre d'objets,
  /// jamais sous [objectObservationMinMs]. Ex. 4 objets → 5 s, 8 → 10 s, 12 → 15 s.
  static int objectObservationMs(int objectCount) {
    final total = objectObservationMsPerItem * objectCount;
    return total < objectObservationMinMs ? objectObservationMinMs : total;
  }

  // ── Calibrage appareil → timeout par tâche (fiche Tableau 2) ──────────────
  /// PROVISOIRE — à calibrer sur données pilotes (95ᵉ percentile). Miroir backend.
  static const int maxTaskTimeMs = 6000;
  static const bool applyCalibrationToTaskTimeout = true;

  /// Timeout effectif, offset de calibrage compris.
  static double adjustedTaskTimeoutMs(double offsetMs) =>
      maxTaskTimeMs + (applyCalibrationToTaskTimeout ? (offsetMs < 0 ? 0 : offsetMs) : 0);

  static bool isTaskTimedOut(int taskTimeMs, double offsetMs) =>
      taskTimeMs > adjustedTaskTimeoutMs(offsetMs);

  // ── Validité de session (fiche Tableau 3) — seuils PROVISOIRES ─────────────
  static const double criticalCalibrationOffsetMs = 100;
  static const int maxTimeoutTasks = 3;

  static bool isSessionValid(double offsetMs, bool sessionCompleted, int timeoutTaskCount) {
    if (offsetMs > criticalCalibrationOffsetMs) return false;
    if (!sessionCompleted) return false;
    if (timeoutTaskCount > maxTimeoutTasks) return false;
    return true;
  }

  /// Note d'une tâche (0–5) à partir d'une précision [0,1].
  static int taskScore(double accuracy) =>
      (accuracy.clamp(0.0, 1.0) * taskMaxScore).round();
}
