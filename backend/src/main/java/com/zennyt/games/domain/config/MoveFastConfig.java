package com.zennyt.games.domain.config;

import java.util.List;

/**
 * Configuration du barème « Je bouge / Move Fast » (Flexibilité cognitive).
 *
 * <p>Java pur, sans Spring : ce sont des invariantes métier issues de la fiche
 * « JE BOUGE » (tableaux <i>Configuration</i> et <i>Calibrage technique révisé</i>).
 * Les constantes sont nommées d'après les clés techniques de la fiche pour
 * faciliter la traçabilité entre la fiche psychométrique et le code.
 *
 * <p>Le barème est <b>calculé côté serveur</b> ({@code PlanifikScoringService})
 * à partir des métriques mesurées — le client ne transmet jamais de points. Le
 * mock mobile ({@code games_mock_repository.dart}) doit reproduire à l'identique
 * ces valeurs.
 */
public final class MoveFastConfig {

    private MoveFastConfig() {
    }

    // ── Barème (fiche « Configuration ») ────────────────────────────────────

    /** {@code base_points_per_correct} — points de base par réponse correcte. */
    public static final int BASE_POINTS_PER_CORRECT = 50;

    /** {@code correct_streak_for_upgrade} — bonnes réponses consécutives pour +1 multiplicateur. */
    public static final int CORRECT_STREAK_FOR_UPGRADE = 4;

    /** {@code max_multiplier} — plafond du multiplicateur. */
    public static final int MAX_MULTIPLIER = 10;

    /** {@code min_multiplier} — plancher du multiplicateur (implicite, ×1). */
    public static final int MIN_MULTIPLIER = 1;

    /** {@code final_bonus_multiplier} — coefficient du bonus de fin (× multiplicateur final). */
    public static final int FINAL_BONUS_MULTIPLIER = 250;

    /** {@code reset_streak_on_error} — remet le compteur de série à zéro sur erreur. */
    public static final boolean RESET_STREAK_ON_ERROR = true;

    /** {@code decrease_multiplier_on_error} — baisse le multiplicateur sur erreur (série vide), min ×1. */
    public static final boolean DECREASE_MULTIPLIER_ON_ERROR = true;

    // ── Calibrage technique révisé (fiche « Calibrage ») ─────────────────────

    /** {@code max_response_time_ms} — au-delà, la réponse est comptée « lente ». */
    public static final int MAX_RESPONSE_TIME_MS = 2000;

    /** {@code min_response_time_ms} — en deçà, la réponse est comptée « rapide » (anticipation). */
    public static final int MIN_RESPONSE_TIME_MS = 250;

    /**
     * Nombre d'essais d'échauffement (warm-up) exclus du scoring ET du calibrage.
     * Correction méthodologique de la fiche révisée (Tableau 2 révisé, voir aussi Tâche 4).
     */
    public static final int PRACTICE_TRIAL_COUNT = 3;

    // ── Condition de fin de session (fiche « Configuration ») ────────────────

    /**
     * Paramètres effectifs de fin de session tels qu'implémentés par le produit.
     *
     * <p>⚠️ <b>DIVERGENCE ASSUMÉE</b> : la fiche d'origine définit
     * {@code session_end_condition = reach_max_multiplier} (aucune limite de temps
     * ni d'essais). Le produit termine en réalité sur 12 bonnes réponses / 18 essais
     * / 84 s. Cette divergence est <b>tracée volontairement</b> et doit être validée
     * par le psychologue référent — ne pas la supprimer sans arbitrage.
     */
    public record SessionEndCondition(int targetCorrectAnswers, int maxResponses, int sessionSeconds) {
    }

    public static final SessionEndCondition SESSION_END_CONDITION =
        new SessionEndCondition(12, 18, 84);

    // ── Interprétation du score (bandes provisoires) ─────────────────────────

    /** Bande d'interprétation : niveau attribué si {@code normalized >= minInclusive}. */
    public record InterpretationBand(double minInclusive, String level) {
    }

    /**
     * Bandes d'interprétation du score normalisé (/100).
     *
     * <p>// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE — bandes provisoires.
     * Ces seuils (&lt;40 / &lt;60 / &lt;75 / &lt;90 / sinon) n'existent dans aucune
     * fiche psychométrique. Ils sont conservés pour l'affichage mais doivent être
     * validés ou remplacés par le psychologue référent.
     */
    public static final List<InterpretationBand> INTERPRETATION_BANDS = List.of(
        new InterpretationBand(90.0, "Excellent"),
        new InterpretationBand(75.0, "Bon"),
        new InterpretationBand(60.0, "Moyen"),
        new InterpretationBand(40.0, "Moyen faible"),
        new InterpretationBand(0.0, "Très faible")
    );

    /** Interprète un score normalisé (/100) selon les bandes provisoires ci-dessus. */
    public static String interpret(double normalized) {
        return INTERPRETATION_BANDS.stream()
            .filter(band -> normalized >= band.minInclusive())
            .map(InterpretationBand::level)
            .findFirst()
            .orElse("Très faible");
    }

    /**
     * Décomposition du rejeu de l'escalade : points de jeu, multiplicateur final
     * et bonus de fin. Sert au calcul du score ET au détail affiché (panneau de
     * score). Barème inchangé (50 × multiplicateur, streak 4, bonus 250).
     */
    public record Replay(int gamePoints, int finalMultiplier, int finalBonus, int total) {
    }

    /** Rejoue la séquence correct/incorrect et expose la décomposition du score. */
    public static Replay replay(Iterable<Boolean> responses) {
        int points = 0;
        int multiplier = MIN_MULTIPLIER;
        int streakCounter = 0;

        for (boolean correct : responses) {
            if (correct) {
                points += BASE_POINTS_PER_CORRECT * multiplier;
                streakCounter++;
                if (streakCounter == CORRECT_STREAK_FOR_UPGRADE) {
                    streakCounter = 0;
                    multiplier = Math.min(MAX_MULTIPLIER, multiplier + 1);
                }
            } else if (RESET_STREAK_ON_ERROR && streakCounter > 0) {
                streakCounter = 0;
            } else if (DECREASE_MULTIPLIER_ON_ERROR) {
                multiplier = Math.max(MIN_MULTIPLIER, multiplier - 1);
            }
        }

        int finalBonus = FINAL_BONUS_MULTIPLIER * multiplier;
        return new Replay(points, multiplier, finalBonus, points + finalBonus);
    }
}
