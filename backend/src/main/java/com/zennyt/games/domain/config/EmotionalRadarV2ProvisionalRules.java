package com.zennyt.games.domain.config;

/**
 * Couche <b>PROVISOIRE</b> d'« Emotional Radar v2 » — un seul fichier, chaque valeur
 * commentée {@code // PROVISOIRE}. Même patron strict que
 * {@link DecisionProvisionalRules} : le moteur (score « jeu », theta, interprétation)
 * ne code jamais ces valeurs en dur, il les lit ici. Remplacer le provisoire par les
 * données de calibration ne demande aucune modification du moteur.
 */
public final class EmotionalRadarV2ProvisionalRules {

    private EmotionalRadarV2ProvisionalRules() {
    }

    // ═══ Score « jeu » (radar_emotion_score, 0–10) ═══════════════════════════
    // PROVISOIRE — le brief dit « basé sur les niveaux, façon jeu vidéo » sans donner
    // la formule. On combine le niveau atteint (poids majeur) et la précision globale.

    /** Poids du niveau final dans le score « jeu » (0..1). PROVISOIRE. */
    public static final double GAME_SCORE_LEVEL_WEIGHT = 0.7;

    /** Poids de la précision globale dans le score « jeu » (0..1). PROVISOIRE. */
    public static final double GAME_SCORE_ACCURACY_WEIGHT = 0.3;

    /** Bornes d'interprétation du niveau global (emotional_level). PROVISOIRE. */
    public static final double EMOTIONAL_LEVEL_HIGH_MIN = 7.0;  // ≥ 7/10 → Élevé
    public static final double EMOTIONAL_LEVEL_MEDIUM_MIN = 4.0; // ≥ 4/10 → Moyen

    /** Niveau global textuel à partir du score « jeu » /10. PROVISOIRE. */
    public static String emotionalLevel(double gameScore) {
        if (gameScore >= EMOTIONAL_LEVEL_HIGH_MIN) return "Élevé";
        if (gameScore >= EMOTIONAL_LEVEL_MEDIUM_MIN) return "Moyen";
        return "Faible";
    }

    // ═══ Couche décisionnelle theta (IRT) — VERROUILLÉE tant que non calibrée ═
    // PROVISOIRE — le brief interdit tout usage décisionnel/RH/clinique tant que la
    // calibration (section 4) n'est pas « Validé ». Ces valeurs sont des points de
    // départ théoriques (2PL), à remplacer par des paramètres empiriques.

    /**
     * {@code decisional_use_allowed} — le theta ne doit JAMAIS servir à comparer des
     * personnes tant que ce drapeau est {@code false}. Ne le passer à {@code true}
     * qu'une fois {@code calibration_status = Validé} (plan §4 du brief).
     */
    public static final boolean DECISIONAL_USE_ALLOWED = false; // PROVISOIRE — NE PAS activer

    /** {@code min_items_for_reliable_theta} — sous ce seuil, theta = « Provisoire ». PROVISOIRE. */
    public static final int MIN_ITEMS_FOR_RELIABLE_THETA = 20;

    /** Discrimination 2PL par item (paramètre a). PROVISOIRE — 1.0 faute de calibration. */
    public static final double IRT_DISCRIMINATION = 1.0;

    /**
     * Amplitude de conversion « distance sémantique → difficulté d'item (b) ».
     * Difficulté théorique b = (0.5 − distance) × ÉCHELLE : distance faible (émotions
     * proches) → item difficile (b élevé). PROVISOIRE.
     */
    public static final double IRT_DIFFICULTY_SCALE = 4.0;

    /** Difficulté 2PL théorique d'un item depuis la distance sémantique de la scène. PROVISOIRE. */
    public static double itemDifficultyFromDistance(double semanticDistance) {
        return (0.5 - semanticDistance) * IRT_DIFFICULTY_SCALE; // PROVISOIRE
    }

    // ═══ Bandes d'interprétation de la reconnaissance émotionnelle (/100) ════
    // PROVISOIRE — alignées sur les autres jeux tant que le psychologue n'a pas tranché.

    public static String interpret(double normalized) {
        if (normalized < 40) return "Très faible";  // PROVISOIRE
        if (normalized < 60) return "Moyen faible";  // PROVISOIRE
        if (normalized < 75) return "Moyen";         // PROVISOIRE
        if (normalized < 90) return "Bon";           // PROVISOIRE
        return "Excellent";                          // PROVISOIRE
    }
}
