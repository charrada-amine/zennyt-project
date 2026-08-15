package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.DifficultyLevel;
import com.zennyt.games.domain.vo.DistanceBand;

import java.util.List;

/**
 * Configuration <b>MOTEUR</b> d'« Emotional Radar v2 » — reprend la table de
 * configuration admin du brief (2026-08-12, « niveaux de choix 6/6/9/9 »). Java pur.
 *
 * <p>Deux axes de difficulté indépendants (charge cognitive = nombre de choix ;
 * finesse = proximité sémantique). Difficulté <b>adaptative</b> : montée &gt; 70 %,
 * descente &lt; 40 %, sur une fenêtre glissante de 3–4 scènes. Les valeurs de bande
 * de distance ({@link DistanceBand}) et le barème du score « jeu » vivent dans la
 * couche provisoire ; ici on ne code que la structure fournie par le brief.
 */
public final class EmotionalRadarV2Config {

    private EmotionalRadarV2Config() {
    }

    // ── Référentiel émotionnel (admin table) ─────────────────────────────────

    /** {@code emotion_pool_size} — 45 émotions (Cowen &amp; Keltner + littérature). */
    public static final int EMOTION_POOL_SIZE = 45;

    /** {@code total_scenes} — scènes par session. */
    public static final int TOTAL_SCENES = 15;

    /** {@code video_library_size} — 45 émotions × 3 intensités. */
    public static final int VIDEO_LIBRARY_SIZE = 135;

    /** Niveaux d'intensité réellement joués dans la vidéo. */
    public static final List<String> STIMULUS_INTENSITY_LEVELS =
        List.of("Faible", "Modérée", "Intense");

    /** Échelle d'intensité perçue par le joueur (distincte de l'intensité produite). */
    public static final List<String> INTENSITY_SCALE = STIMULUS_INTENSITY_LEVELS;

    // ── Difficulté adaptative (admin table) ──────────────────────────────────

    /** {@code difficulty_levels} — 4 niveaux. */
    public static final int DIFFICULTY_LEVELS = 4;

    /**
     * {@code choices_per_level} — 6 / 6 / 9 / 9 (mis à jour depuis 6/6/8/8, grille 3×3).
     * Combiné à {@code target_distance_per_level} = Élevée / Moyenne / Élevée / Faible.
     */
    public static final List<DifficultyLevel> LEVELS = List.of(
        new DifficultyLevel(1, 6, DistanceBand.HIGH),    // facile
        new DifficultyLevel(2, 6, DistanceBand.MEDIUM),  // finesse moyenne
        new DifficultyLevel(3, 9, DistanceBand.HIGH),    // charge cognitive isolée
        new DifficultyLevel(4, 9, DistanceBand.LOW)      // charge + finesse combinées
    );

    /** {@code level_up_threshold_percent} — réussite pour monter de niveau. */
    public static final double LEVEL_UP_THRESHOLD = 0.70;

    /** {@code level_down_threshold_percent} — réussite en dessous de laquelle on redescend. */
    public static final double LEVEL_DOWN_THRESHOLD = 0.40;

    /** {@code evaluation_window_scenes} — fenêtre glissante (min..max). */
    public static final int EVALUATION_WINDOW_MIN = 3;
    public static final int EVALUATION_WINDOW_MAX = 4;

    /** Niveau de départ par défaut d'une session. */
    public static final int STARTING_LEVEL = 1;

    // ── Timing (admin table) ─────────────────────────────────────────────────

    /** {@code max_response_time_ms} — temps max autorisé pour répondre. */
    public static final int MAX_RESPONSE_TIME_MS = 8000;

    /** {@code min_impulsive_time_ms} — réponse trop rapide (absence d'analyse). */
    public static final int MIN_IMPULSIVE_TIME_MS = 400;

    // ── Norming / gouvernance (admin table) ──────────────────────────────────

    /** {@code norming_required_before_use} — chaque vidéo validée par un panel. */
    public static final boolean NORMING_REQUIRED_BEFORE_USE = true;

    /** {@code require_explanation} — justification textuelle demandée au joueur (0–5). */
    public static final boolean REQUIRE_EXPLANATION = true;

    public static final int JUSTIFICATION_MIN_SCORE = 0;
    public static final int JUSTIFICATION_MAX_SCORE = 5;

    /** Niveau par son numéro (1..4). */
    public static DifficultyLevel level(int levelNumber) {
        if (levelNumber < 1 || levelNumber > LEVELS.size()) {
            throw new IllegalArgumentException("niveau hors 1.." + LEVELS.size() + " : " + levelNumber);
        }
        return LEVELS.get(levelNumber - 1);
    }

    /** Nombre de choix proposés au niveau donné. */
    public static int choicesForLevel(int levelNumber) {
        return level(levelNumber).choicesCount();
    }
}
