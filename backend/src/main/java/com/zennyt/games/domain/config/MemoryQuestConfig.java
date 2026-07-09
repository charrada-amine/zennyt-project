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

    // ── Difficulté niveau 1 (le reste : à venir) ─────────────────────────────
    public static final int START_DIGIT_LENGTH = 4;
    public static final int MAX_DIGIT_LENGTH = 9;
    public static final int OBJECT_COUNT_L1 = 4;
    public static final int MANIPULATIONS_L1 = 2;
    public static final int DISTRACTION_SECONDS = 8; // 5–10 s

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
