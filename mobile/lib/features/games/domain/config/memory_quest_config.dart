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
