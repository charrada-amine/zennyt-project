package com.zennyt.games.domain.config;

import java.util.List;

/**
 * Configuration du jeu « J'investigue » (GameType MEMORY_QUEST, mémoire de travail).
 *
 * <p>Java pur, sans Spring : règles issues du developer handoff « J'investigue ».
 * Le score est <b>calculé côté serveur</b> à partir des mesures brutes (le client
 * n'envoie jamais de points). Le mock mobile ({@code games_mock_repository.dart})
 * reproduit ce barème à l'identique.
 *
 * <p>Barème : chaque tâche (rappel même ordre, rappel inverse, restauration
 * d'objets, rappel après distraction) est notée <b>0–5</b> ; le composite est la
 * <b>moyenne des tâches jouées, normalisée /100</b> (indicatif, non diagnostique).
 */
public final class MemoryQuestConfig {

    private MemoryQuestConfig() {
    }

    /** Échelle de note par tâche (0–5). */
    public static final int TASK_MAX_SCORE = 5;

    /** Maximum du composite (/100). */
    public static final int COMPOSITE_MAX = 100;

    // ── Timings d'encodage (data-driven, handoff §6/§8) ──────────────────────
    public static final int DIGIT_VISIBLE_MS = 900;
    public static final int ISI_MS = 250;
    public static final int MANIPULATIONS_L1 = 2;
    public static final int DISTRACTION_SECONDS = 8; // 5–10 s

    // ── Système de niveaux (fiche « J'INVESTIGUE », Tableau 1) ────────────────

    /** {@code initial_sequence_length} — longueur de séquence au niveau 1. */
    public static final int INITIAL_SEQUENCE_LENGTH = 3;

    /** {@code sequence_increment} — +1 longueur par niveau. */
    public static final int SEQUENCE_INCREMENT = 1;

    /** {@code max_sequence_length} — longueur maximale testable. */
    public static final int MAX_SEQUENCE_LENGTH = 9;

    /** {@code total_levels} — 7 longueurs testables (3, 4, 5, 6, 7, 8, 9). */
    public static final int TOTAL_LEVELS = 7;

    /** {@code correct_tasks_for_level_up} — tâches réussies pour monter d'un niveau. */
    public static final int CORRECT_TASKS_FOR_LEVEL_UP = 3;

    /**
     * {@code reset_sequence_on_error} — sur erreur, la SÉQUENCE du prochain essai
     * est régénérée (nouvelle séquence), sans effacer le niveau déjà acquis. Le
     * crédit partiel (0–5) est calculé sur l'essai qui vient d'échouer,
     * indépendamment de ce reset.
     */
    public static final boolean RESET_SEQUENCE_ON_ERROR = true;

    /**
     * Nombre d'objets (Mission B) — un de plus par niveau à partir de
     * {@link #MIN_OBJECT_COUNT}, plafonné à {@link #MAX_OBJECT_COUNT}.
     *
     * <p>Le plancher est passé de 4 à <b>3</b> pour adoucir l'entrée dans le jeu
     * (demande client). Miroir de {@code memory_quest_config.dart}.
     */
    public static final int MIN_OBJECT_COUNT = 3;
    public static final int MAX_OBJECT_COUNT = 12;

    /**
     * {@code distraction_min_level} — la phase de distraction est <b>gatée</b> :
     * absente aux niveaux 1–2, active à partir du niveau 3.
     */
    public static final int DISTRACTION_MIN_LEVEL = 3;

    /** {@code hints_enabled} = false (mode évaluation : aucun indice). */
    public static final boolean HINTS_ENABLED = false;

    /** {@code partial_credit_enabled} = true (crédit partiel, cotation 0–5). */
    public static final boolean PARTIAL_CREDIT_ENABLED = true;

    /** {@code max_session_duration_min} — borne haute de la fiche. */
    public static final int MAX_SESSION_DURATION_MIN = 30;

    // ── Calibrage appareil → timeout par tâche (fiche Tableau 2) ─────────────
    // Memory Quest est le PREMIER module dont le score dépend du temps : le
    // socle DeviceCalibration / CalibrationService (déjà construit, non modifié)
    // est enfin exploité pour un score, pas seulement des indicateurs.

    /**
     * {@code max_task_time_ms} — délai max d'une tâche avant échec par dépassement.
     *
     * <p>// PROVISOIRE — à calibrer sur données pilotes (95ᵉ percentile observé).
     * La fiche indique qu'aucune valeur scientifique ne s'impose. Tracé dans
     * « Décisions à valider » (GAMES_MODULE.md).
     */
    public static final int MAX_TASK_TIME_MS = 6000;

    /**
     * {@code apply_calibration_to_task_timeout} — le délai est augmenté de
     * l'offset de calibrage avant de déclarer un échec, pour ne pas pénaliser un
     * appareil lent. C'est « l'ajustement serveur » du score final (fiche).
     */
    public static final boolean APPLY_CALIBRATION_TO_TASK_TIMEOUT = true;

    /**
     * Délai de timeout effectif, offset de calibrage compris : {@code max_task_time_ms
     * + calibration_offset_ms} (si l'ajustement est activé). L'offset provient de
     * {@code CalibrationService.offsetMs(deviceCalibration)} — socle réutilisé.
     *
     * @param calibrationOffsetMs offset technique de l'appareil (0 si aucun calibrage)
     */
    public static double adjustedTaskTimeoutMs(double calibrationOffsetMs) {
        double offset = APPLY_CALIBRATION_TO_TASK_TIMEOUT ? Math.max(0.0, calibrationOffsetMs) : 0.0;
        return MAX_TASK_TIME_MS + offset;
    }

    /**
     * true si une tâche est en échec par DÉPASSEMENT DE TEMPS (au-delà du timeout
     * ajusté du calibrage). Une tâche non échouée ici garde sa note de rappel ;
     * l'ajustement du calibrage ne fait que remonter le seuil pour un appareil lent.
     *
     * @param taskTimeMs          temps brut mesuré de la tâche
     * @param calibrationOffsetMs offset de calibrage de l'appareil
     */
    public static boolean isTaskTimedOut(long taskTimeMs, double calibrationOffsetMs) {
        return taskTimeMs > adjustedTaskTimeoutMs(calibrationOffsetMs);
    }

    // ── Validité de session (fiche Tableau 3) ────────────────────────────────

    /**
     * Seuil critique d'offset de calibrage : au-delà, l'appareil est jugé trop
     * peu fiable et la session est invalidée.
     *
     * <p>// PROVISOIRE — non chiffré par la fiche ; à calibrer sur données pilotes.
     * Tracé dans « Décisions à valider » (GAMES_MODULE.md).
     */
    public static final double CRITICAL_CALIBRATION_OFFSET_MS = 100.0;

    /**
     * Nombre max de tâches en échec par DÉPASSEMENT DE TEMPS toléré avant
     * d'invalider la session (au-delà, trop de timeouts vs erreurs de rappel).
     *
     * <p>// PROVISOIRE — non chiffré par la fiche ; à calibrer sur données pilotes.
     * Tracé dans « Décisions à valider » (GAMES_MODULE.md).
     */
    public static final int MAX_TIMEOUT_TASKS = 3;

    /**
     * {@code session_valid} — false si l'un des cas de la fiche (Tableau 3) :
     * <ol>
     *   <li>offset de calibrage &gt; {@link #CRITICAL_CALIBRATION_OFFSET_MS}
     *       (appareil trop peu fiable) ;</li>
     *   <li>la session n'atteint pas sa condition de fin (abandon) ;</li>
     *   <li>trop de tâches échouées par timeout (&gt; {@link #MAX_TIMEOUT_TASKS})
     *       plutôt que par erreur de rappel.</li>
     * </ol>
     *
     * @param calibrationOffsetMs offset de calibrage de l'appareil
     * @param sessionCompleted    true si la condition de fin a été atteinte
     * @param timeoutTaskCount    nb de tâches en échec par dépassement de temps
     */
    public static boolean isSessionValid(double calibrationOffsetMs,
                                         boolean sessionCompleted, int timeoutTaskCount) {
        if (calibrationOffsetMs > CRITICAL_CALIBRATION_OFFSET_MS) {
            return false; // (1) appareil jugé trop peu fiable
        }
        if (!sessionCompleted) {
            return false; // (2) abandon avant la fin
        }
        if (timeoutTaskCount > MAX_TIMEOUT_TASKS) {
            return false; // (3) trop de timeouts (dépassement) vs erreurs de rappel
        }
        return true;
    }

    /** Longueur de séquence attendue à un niveau (1-based) : {@code 3 + (level−1)}, plafonnée. */
    public static int sequenceLengthForLevel(int level) {
        int len = INITIAL_SEQUENCE_LENGTH + (Math.max(1, level) - 1) * SEQUENCE_INCREMENT;
        return Math.min(MAX_SEQUENCE_LENGTH, len);
    }

    /**
     * Nombre d'objets (Mission B) à un niveau (1-based) : <b>un objet de plus par
     * niveau</b> à partir de {@link #MIN_OBJECT_COUNT} — 3, 4, 5, 6… — plafonné à
     * {@link #MAX_OBJECT_COUNT}.
     *
     * <p>La progression était interpolée de bout en bout sur {@link #TOTAL_LEVELS},
     * ce qui donnait 4, 5, 7, 8, 9, 11, 12 : la charge sautait de deux objets à
     * certains paliers. Le pas constant reprend la mécanique du jeu de chiffres
     * (un chiffre de plus par niveau). Miroir de {@code memory_quest_config.dart}.
     */
    public static int objectCountForLevel(int level) {
        int count = MIN_OBJECT_COUNT + Math.max(1, level) - 1;
        return Math.min(count, MAX_OBJECT_COUNT);
    }

    // ── Difficulté des distractions visuelles (jeu des IMAGES) ───────────────
    //
    // Point de calibration UNIQUE de la montée en difficulté des tâches
    // parasites : durée, taille de grille, ressemblance, nombre de pièces.
    // Miroir de {@code memory_quest_config.dart}.

    /**
     * Niveau à partir duquel le jeu des <b>IMAGES</b> intercale une tâche
     * parasite — plus tôt que le jeu des chiffres
     * ({@link #DISTRACTION_MIN_LEVEL}), les deux courbes différant.
     */
    public static final int IMAGES_DISTRACTION_MIN_LEVEL = 2;

    public static boolean imagesDistractionActiveAtLevel(int level) {
        return level >= IMAGES_DISTRACTION_MIN_LEVEL;
    }

    /** Durée d'une tâche parasite au premier niveau où elle apparaît. */
    public static final int DISTRACTION_BASE_TIME_LIMIT_MS = 12_000;

    /** Temps retiré par niveau au-delà de {@link #DISTRACTION_MIN_LEVEL}. */
    public static final int DISTRACTION_TIME_STEP_MS = 500;

    /** Plancher : en deçà, la tâche cesse d'être faisable. */
    public static final int DISTRACTION_MIN_TIME_LIMIT_MS = 6_000;

    /**
     * Budget de temps d'une tâche parasite — <b>identique pour les deux
     * familles</b> (intrus / pièce manquante) et jamais illimité.
     */
    public static int distractionTimeLimitMs(int level) {
        int steps = Math.max(0, level - IMAGES_DISTRACTION_MIN_LEVEL);
        int ms = DISTRACTION_BASE_TIME_LIMIT_MS - steps * DISTRACTION_TIME_STEP_MS;
        return Math.max(ms, DISTRACTION_MIN_TIME_LIMIT_MS);
    }

    /** Cases de la grille « intrus » : 4, puis deux de plus par niveau. */
    public static final int DISTRACTION_MIN_GRID_CELLS = 4;
    public static final int DISTRACTION_MAX_GRID_CELLS = 12;

    public static int oddOneOutCellCount(int level) {
        int steps = Math.max(0, level - IMAGES_DISTRACTION_MIN_LEVEL);
        return Math.min(DISTRACTION_MIN_GRID_CELLS + steps * 2, DISTRACTION_MAX_GRID_CELLS);
    }

    /** Ressemblance de l'intrus dans [0,1] : plus haute = écart plus ténu. */
    public static final double DISTRACTION_BASE_SIMILARITY = 0.35;
    public static final double DISTRACTION_SIMILARITY_STEP = 0.10;
    public static final double DISTRACTION_MAX_SIMILARITY = 0.85;

    public static double oddOneOutSimilarity(int level) {
        int steps = Math.max(0, level - IMAGES_DISTRACTION_MIN_LEVEL);
        double s = DISTRACTION_BASE_SIMILARITY + steps * DISTRACTION_SIMILARITY_STEP;
        return Math.min(s, DISTRACTION_MAX_SIMILARITY);
    }

    /** Côté du puzzle : 2×2, puis un cran tous les deux niveaux, max 4×4. */
    public static final int PUZZLE_MIN_GRID_SIDE = 2;
    public static final int PUZZLE_MAX_GRID_SIDE = 4;

    public static int puzzleGridSide(int level) {
        int steps = Math.max(0, level - IMAGES_DISTRACTION_MIN_LEVEL);
        return Math.min(PUZZLE_MIN_GRID_SIDE + steps / 2, PUZZLE_MAX_GRID_SIDE);
    }

    /** Pièces proposées (une seule correcte) : 3, puis une de plus par niveau. */
    public static final int PUZZLE_MIN_OPTIONS = 3;
    public static final int PUZZLE_MAX_OPTIONS = 6;

    public static int puzzleOptionCount(int level) {
        int steps = Math.max(0, level - IMAGES_DISTRACTION_MIN_LEVEL);
        return Math.min(PUZZLE_MIN_OPTIONS + steps, PUZZLE_MAX_OPTIONS);
    }

    /**
     * Timeout d'une tâche PARASITE : c'est son propre budget qui fait foi, pas
     * {@link #MAX_TASK_TIME_MS}.
     */
    public static boolean isDistractionTimedOut(int taskTimeMs, int level, double offsetMs) {
        double limit = distractionTimeLimitMs(level)
            + (APPLY_CALIBRATION_TO_TASK_TIMEOUT ? Math.max(0, offsetMs) : 0);
        return taskTimeMs > limit;
    }

    /** true si la distraction est jouée à ce niveau (gatée à {@link #DISTRACTION_MIN_LEVEL}). */
    public static boolean distractionActiveAtLevel(int level) {
        return level >= DISTRACTION_MIN_LEVEL;
    }

    /** Note d'une tâche (0–5) à partir d'une précision [0,1] : {@code round(acc × 5)}. */
    public static int taskScore(double accuracy) {
        double clamped = Math.max(0.0, Math.min(1.0, accuracy));
        return (int) Math.round(clamped * TASK_MAX_SCORE);
    }

    // ── Interprétation du composite (bandes provisoires) ─────────────────────

    /** Bande d'interprétation : niveau attribué si {@code composite >= minInclusive}. */
    public record InterpretationBand(int minInclusive, String level) {
    }

    /**
     * Bandes d'interprétation du composite (/100).
     *
     * <p>// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE — bandes provisoires (mêmes seuils
     * indicatifs que les autres jeux). Le résultat est présenté comme
     * <b>indicatif, non diagnostique</b>.
     */
    public static final List<InterpretationBand> INTERPRETATION_BANDS = List.of(
        new InterpretationBand(90, "Excellent"),
        new InterpretationBand(75, "Bon"),
        new InterpretationBand(60, "Moyen"),
        new InterpretationBand(40, "Moyen faible"),
        new InterpretationBand(0, "Très faible")
    );

    /** Interprète un composite /100 selon les bandes provisoires ci-dessus. */
    public static String interpret(int composite) {
        return INTERPRETATION_BANDS.stream()
            .filter(band -> composite >= band.minInclusive())
            .map(InterpretationBand::level)
            .findFirst()
            .orElse("Très faible");
    }
}
