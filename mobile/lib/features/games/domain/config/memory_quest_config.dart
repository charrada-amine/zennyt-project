// Miroir Dart de `MemoryQuestConfig` (backend) — source UNIQUE côté mobile pour
// le système de niveaux, le timeout par tâche (calibrage) et la validité de
// session. L'écran et le mock lisent ces valeurs pour rester alignés backend ⇄ mock.

import 'dart:math' as math;

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
  //
  // MODÈLE : le temps accordé n'est PAS proportionnel au nombre d'objets. Il
  // suit une droite brisée au seuil de la mémoire de travail visuelle, estimée
  // à 4 ± 1 objets (Cowan, 2001) :
  //
  //   T(n) = base + perItem·n + rehearsal·max(0, n − capacity)
  //
  //   • `base`      — coût perceptif fixe : première saccade, lecture globale
  //                   de la grille, indépendant du nombre d'objets ;
  //   • `perItem`   — encodage d'une image. La littérature situe l'encodage
  //                   fiable d'une image entre 0,5 et 1 s (Potter, 1976 ;
  //                   Brady et al., PNAS 2008) ; le coût croît linéairement
  //                   avec le nombre d'éléments (Sternberg, Science 1966) ;
  //   • `rehearsal` — surcoût au-delà de la capacité : le joueur ne peut plus
  //                   tout tenir d'un coup et doit regrouper puis répéter
  //                   (Miller, 1956). C'est ce terme, absent d'un modèle
  //                   linéaire, qui rend les niveaux hauts jouables.
  //
  // Remplace un barème strictement proportionnel (1,25 s × n, plancher 5 s) qui
  // sur-dotait les petits lots — 5 s pour 3 objets, alors qu'ils tiennent en
  // mémoire de travail sans répétition — et sous-dotait les grands.

  /// Coût perceptif fixe, indépendant du nombre d'objets (ms).
  static const int objectObservationBaseMs = 2000;

  /// Encodage d'une image (ms), tant qu'on reste sous [workingMemoryCapacity].
  static const int objectObservationMsPerItem = 800;

  /// Surcoût de regroupement/répétition par objet AU-DELÀ de la capacité (ms).
  static const int objectObservationRehearsalMsPerItem = 500;

  /// Capacité de la mémoire de travail visuelle (Cowan, 2001) : le point où la
  /// pente change.
  static const int workingMemoryCapacity = 4;

  /// Plancher physiologique par objet (ms) : une fixation oculaire dure
  /// ~250-300 ms, donc en deçà le joueur n'a pas même le temps de poser les
  /// yeux sur chaque image. Ce plancher borne aussi l'ajustement individuel :
  /// sans lui, un joueur performant finirait par recevoir des niveaux
  /// littéralement infaisables.
  static const int objectObservationMinMsPerItem = 300;

  /// Plancher absolu du temps d'observation (ms).
  static const int objectObservationMinMs = 1500;

  /// Plafond du temps d'observation (ms). Au-delà, l'attention retombe : le
  /// joueur ne retient pas mieux, il s'ennuie.
  static const int objectObservationMaxMs = 30000;

  /// Temps d'observation des objets, en ms.
  ///
  /// [playerFactor] est le coefficient d'allure du joueur ([playerPaceNeutral]
  /// par défaut) — voir [nextPlayerFactor].
  ///
  /// Ex. à allure neutre : 3 objets → 4,4 s · 4 → 5,2 s · 6 → 7,8 s ·
  /// 9 → 11,7 s · 12 → 15,6 s.
  static int objectObservationMs(
    int objectCount, {
    double playerFactor = playerPaceNeutral,
  }) {
    final n = objectCount < 0 ? 0 : objectCount;
    final over = n - workingMemoryCapacity;
    final base = objectObservationBaseMs +
        objectObservationMsPerItem * n +
        objectObservationRehearsalMsPerItem * (over < 0 ? 0 : over);

    final scaled = (base * playerFactor).round();

    final fixationFloor = objectObservationMinMsPerItem * n;
    final floor = fixationFloor > objectObservationMinMs
        ? fixationFloor
        : objectObservationMinMs;

    if (scaled < floor) return floor;
    return scaled > objectObservationMaxMs ? objectObservationMaxMs : scaled;
  }

  // ── Temps de restitution (loi de Hick) ─────────────────────────────────────
  //
  // La restitution ne suit PAS la même loi que la mémorisation. Le joueur n'a
  // plus rien à encoder : il choisit, parmi les cartes affichées, laquelle
  // placer. Le temps de décision croît alors en logarithme du nombre d'options
  // (Hick, 1952 ; Hyman, 1953) :
  //
  //   T(n) = base + perDoubling · log2(n + 1)
  //
  // Réutiliser ici la droite de la mémorisation serait la faute classique : elle
  // rend les grands niveaux très généreux et les petits étouffants, alors que
  // c'est l'inverse qu'il faut. Ex. 3 objets → 5,9 s · 6 → 7,7 s · 9 → 8,8 s :
  // trois fois plus de cartes ne demandent pas trois fois plus de temps.

  /// Part fixe du temps de restitution (ms) : lecture de la consigne, premier
  /// balayage du plateau.
  static const int restoreBaseMs = 1500;

  /// Temps ajouté chaque fois que le nombre d'options double (ms).
  static const int restoreMsPerDoubling = 2200;

  /// Plancher absolu du temps de restitution (ms).
  static const int restoreMinMs = 4000;

  /// Plafond du temps de restitution (ms).
  static const int restoreMaxMs = 25000;

  /// Temps accordé pour reconstituer l'ordre, en ms.
  ///
  /// [playerFactor] est le même coefficient d'allure que la mémorisation : un
  /// joueur lent doit l'être sur les deux phases, sinon on lui rend d'un côté
  /// ce qu'on lui retire de l'autre.
  static int restoreTimeLimitMs(
    int objectCount, {
    double playerFactor = playerPaceNeutral,
  }) {
    final n = objectCount < 0 ? 0 : objectCount;
    final base =
        restoreBaseMs + restoreMsPerDoubling * (math.log(n + 1) / math.ln2);
    final scaled = (base * playerFactor).round();
    if (scaled < restoreMinMs) return restoreMinMs;
    return scaled > restoreMaxMs ? restoreMaxMs : scaled;
  }

  // ── Allure individuelle (escalier adaptatif) ───────────────────────────────
  //
  // Les constantes ci-dessus sont des moyennes de population ; un joueur donné
  // s'en écarte facilement de ±40 %. Le coefficient d'allure les recale, partie
  // après partie, par un escalier pondéré (Kaernbach, 1991) : le temps se réduit
  // d'un petit pas après un niveau réussi, et remonte d'un pas nettement plus
  // grand après un échec. Le rapport des deux pas fixe le point d'équilibre, ici
  // [targetSuccessRate] — le taux de réussite auquel l'apprentissage et
  // l'engagement sont maximaux (Wilson et al., Nature Communications, 2019).

  /// Coefficient neutre : le joueur reçoit exactement le barème de référence.
  static const double playerPaceNeutral = 1.0;

  /// Taux de réussite visé par l'escalier.
  static const double targetSuccessRate = 0.85;

  /// Pas de remontée après un échec, en log-temps. Règle la vitesse de
  /// convergence : plus haut = adaptation plus rapide mais plus instable.
  static const double playerPaceStepUp = 0.12;

  /// Bornes du coefficient. Elles garantissent qu'aucune série de réussites ne
  /// rende un niveau infaisable, ni qu'une série d'échecs ne le rende gratuit.
  static const double playerPaceMin = 0.6;
  static const double playerPaceMax = 1.8;

  /// Coefficient d'allure après un niveau, selon qu'il est réussi ou raté.
  ///
  /// Le pas de descente vaut `stepUp × (1 − p) / p` : c'est ce rapport qui fait
  /// converger l'escalier vers [targetSuccessRate] plutôt que vers 50 %.
  static double nextPlayerFactor(double current, {required bool success}) {
    final stepDown =
        playerPaceStepUp * (1 - targetSuccessRate) / targetSuccessRate;
    final next = current * math.exp(success ? -stepDown : playerPaceStepUp);
    if (next < playerPaceMin) return playerPaceMin;
    return next > playerPaceMax ? playerPaceMax : next;
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
