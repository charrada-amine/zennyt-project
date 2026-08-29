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

  /// Échecs tolérés **dans un même niveau** avant la fin de la partie.
  ///
  /// Un tour raté ne fait pas monter de niveau : on rejoue le MÊME niveau avec
  /// une nouvelle séquence (cf. [resetSequenceOnError]). Au [maxFailuresPerLevel]
  /// ᵉ échec consécutif sur ce niveau, la partie s'arrête et l'écran de score
  /// s'affiche. Le compteur repart à zéro à chaque montée de niveau.
  ///
  /// Remplace un budget d'erreurs GLOBAL (3 sur toute la partie) qui ne
  /// correspondait pas au déroulé attendu : il additionnait des échecs de
  /// niveaux différents, et surtout le niveau montait même après un tour raté.
  static const int maxFailuresPerLevel = 2;
  static const bool resetSequenceOnError = true;
  /// Objets au premier niveau. Abaissé de 4 à **3** pour adoucir l'entrée dans
  /// le jeu, à la demande du client.
  static const int minObjectCount = 3;
  static const int maxObjectCount = 12;

  /// Niveau à partir duquel le jeu des **IMAGES** intercale une tâche parasite.
  ///
  /// Plus tôt que dans le jeu des chiffres ([distractionMinLevel]) : les deux
  /// jeux n'ont pas la même courbe, et le client veut voir les casse-tête
  /// visuels dès le second palier.
  static const int imagesDistractionMinLevel = 2;

  /// La tâche parasite visuelle est-elle due à ce niveau ?
  static bool imagesDistractionActiveAtLevel(int level) =>
      level >= imagesDistractionMinLevel;

  /// Niveau à partir duquel le jeu des **CHIFFRES** intercale sa question
  /// d'interférence (niveaux 1-2 sans, puis à CHAQUE niveau à partir de
  /// celui-ci).
  ///
  /// A brièvement valu 1 : le client signalait que le distracteur ne se voyait
  /// jamais, et le gating au niveau ≥ 3 en semblait la cause. La cause réelle
  /// était ailleurs — la distraction n'était accrochée qu'à la fin de la mission
  /// d'objets, donc absente du jeu des chiffres quel que soit le niveau (voir
  /// `_endLevelOrDistract` dans `investigate_screen.dart`). Ce point corrigé, le
  /// gating retrouve sa valeur de fiche, qui est aussi celle du backend
  /// (`MemoryQuestConfig.DISTRACTION_MIN_LEVEL = 3`) : les deux avaient divergé.
  static const int distractionMinLevel = 3;
  static const bool hintsEnabled = false;
  static const bool partialCreditEnabled = true;
  static const int maxSessionDurationMin = 30;

  /// Longueur de séquence à un niveau (1-based) : 3 + (level-1), plafonnée à 9.
  static int sequenceLengthForLevel(int level) {
    final len = initialSequenceLength + (level.clamp(1, 1 << 30) - 1) * sequenceIncrement;
    return len < maxSequenceLength ? len : maxSequenceLength;
  }

  /// Nombre d'objets (mémoire des images) à un niveau : **un objet de plus par
  /// niveau**, à partir de [minObjectCount] — 3, 4, 5, 6… plafonné à
  /// [maxObjectCount].
  ///
  /// La progression était auparavant interpolée de 4 à 12 sur les 7 niveaux, ce
  /// qui donnait 4, 5, 7, 8, 9, 11, 12 : la charge sautait de deux objets à
  /// certains paliers. Le pas constant reprend la mécanique du jeu de chiffres
  /// (un chiffre de plus par niveau), demandée par le client.
  static int objectCountForLevel(int level) {
    final count = minObjectCount + (level.clamp(1, 1 << 30) - 1);
    return count < maxObjectCount ? count : maxObjectCount;
  }

  /// Distraction active à partir de [distractionMinLevel].
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

  // ── Difficulté des distractions visuelles (jeu des IMAGES) ────────────────
  //
  // Toute la montée en difficulté des tâches parasites est décrite ICI : durée,
  // taille de grille, ressemblance des éléments, nombre de pièces candidates.
  // Aucune de ces valeurs ne doit être réécrite ailleurs — c'est le point de
  // calibration unique.

  /// Durée d'une tâche parasite au premier niveau où elle apparaît.
  ///
  /// **Identique pour les deux types** (« intrus » et « pièce manquante ») :
  /// deux budgets de temps différents rendraient les niveaux incomparables.
  static const int distractionBaseTimeLimitMs = 12000;

  /// Temps retiré à chaque niveau au-delà de [distractionMinLevel].
  static const int distractionTimeStepMs = 500;

  /// Plancher : en deçà, la tâche cesse d'être faisable et ne mesure plus rien.
  static const int distractionMinTimeLimitMs = 6000;

  /// Budget de temps d'une tâche parasite à un niveau donné — **jamais illimité**.
  static int distractionTimeLimitMs(int level) {
    final steps = (level - imagesDistractionMinLevel).clamp(0, 1 << 30);
    final ms = distractionBaseTimeLimitMs - steps * distractionTimeStepMs;
    return ms < distractionMinTimeLimitMs ? distractionMinTimeLimitMs : ms;
  }

  /// Nombre de cases de la grille « trouver l'intrus » : 4 au premier niveau,
  /// deux de plus par niveau, plafonné à [distractionMaxGridCells].
  static const int distractionMinGridCells = 4;
  static const int distractionMaxGridCells = 12;

  static int oddOneOutCellCount(int level) {
    final steps = (level - imagesDistractionMinLevel).clamp(0, 1 << 30);
    final cells = distractionMinGridCells + steps * 2;
    return cells < distractionMaxGridCells ? cells : distractionMaxGridCells;
  }

  /// Ressemblance entre l'intrus et les autres cases, dans [0, 1] : plus elle
  /// est haute, plus l'écart visuel est ténu — donc plus la recherche est
  /// longue. 0,35 au premier niveau, +0,1 par niveau, plafonnée.
  static const double distractionBaseSimilarity = 0.35;
  static const double distractionSimilarityStep = 0.10;
  static const double distractionMaxSimilarity = 0.85;

  static double oddOneOutSimilarity(int level) {
    final steps = (level - imagesDistractionMinLevel).clamp(0, 1 << 30);
    final s = distractionBaseSimilarity + steps * distractionSimilarityStep;
    return s > distractionMaxSimilarity ? distractionMaxSimilarity : s;
  }

  /// Côté de la grille du puzzle : 2×2, puis 3×3, puis 4×4 — un cran tous les
  /// deux niveaux.
  static const int puzzleMinGridSide = 2;
  static const int puzzleMaxGridSide = 4;

  static int puzzleGridSide(int level) {
    final steps = (level - imagesDistractionMinLevel).clamp(0, 1 << 30);
    final side = puzzleMinGridSide + steps ~/ 2;
    return side > puzzleMaxGridSide ? puzzleMaxGridSide : side;
  }

  /// Pièces proposées pour combler le trou (une seule est correcte) : 3 au
  /// premier niveau, une de plus par niveau.
  static const int puzzleMinOptions = 3;
  static const int puzzleMaxOptions = 6;

  static int puzzleOptionCount(int level) {
    final steps = (level - imagesDistractionMinLevel).clamp(0, 1 << 30);
    final n = puzzleMinOptions + steps;
    return n > puzzleMaxOptions ? puzzleMaxOptions : n;
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

  /// Timeout d'une tâche PARASITE : c'est son propre budget qui fait foi, pas
  /// [maxTaskTimeMs].
  ///
  /// Sans cette distinction, une tâche parasite résolue en 8 s — dans les temps
  /// vis-à-vis de son chronomètre de 12 s — serait quand même voidée par le
  /// seuil générique de 6 s. Le joueur serait puni deux fois pour un essai
  /// réussi.
  static bool isDistractionTimedOut(int taskTimeMs, int level, double offsetMs) {
    final limit = distractionTimeLimitMs(level) +
        (applyCalibrationToTaskTimeout ? (offsetMs < 0 ? 0 : offsetMs) : 0);
    return taskTimeMs > limit;
  }

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
