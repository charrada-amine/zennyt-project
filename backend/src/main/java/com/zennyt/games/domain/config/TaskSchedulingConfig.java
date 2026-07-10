package com.zennyt.games.domain.config;

/**
 * Configuration du mini-jeu « Ordonnancement de tâches » (Planifik #2 — Planification).
 *
 * <p>Java pur, sans Spring : invariantes métier issues de la fiche
 * « JE PLANIFIE — Mini-jeu 2 ». Le barème est <b>calculé côté serveur</b>
 * ({@code PlanifikScoringService}) — le client n'envoie jamais de points. Le mock
 * mobile ({@code games_mock_repository.dart}) doit reproduire ces valeurs.
 *
 * <p>Barème /10 : dépendances (tout-ou-rien) + contraintes horaires (tout-ou-rien)
 * + cohérence (0–2) + réajustements (score dérivé du nombre brut).
 */
public final class TaskSchedulingConfig {

    private TaskSchedulingConfig() {
    }

    // ── Poids du barème (fiche : 3 + 3 + 2 + 2 = /10) ────────────────────────

    /** {@code dependencies_respected} — tout-ou-rien (3 pts si TOUTES respectées, sinon 0). */
    public static final int DEPENDENCIES_POINTS = 3;

    /** {@code time_constraints_respected} — tout-ou-rien (3 pts ou 0). */
    public static final int TIME_CONSTRAINTS_POINTS = 3;

    /** {@code planning_coherence} — 0 désordonné · 1 partiel · 2 clair (0–2 pts). */
    public static final int PLANNING_COHERENCE_MAX_POINTS = 2;

    /** {@code adjustment_score} — maximum du critère réajustements (2 pts). */
    public static final int ADJUSTMENT_MAX_POINTS = 2;

    /** Maximum du barème du mini-jeu. */
    public static final int MAX_POINTS = 10;

    // ── Seuils du score de réajustements (fiche) ─────────────────────────────
    // <2 réajustements → 2 pts · 2 à 4 → 1 pt · >4 → 0 pt.
    // ⚠️ La valeur 2 tombe dans la tranche « 2 à 4 » = 1 pt (et non 2 pts).

    /** En-dessous de ce nombre de réajustements → {@link #ADJUSTMENT_MAX_POINTS}. */
    public static final int ADJUSTMENT_LOW_THRESHOLD = 2; // strictement < 2 → 2 pts

    /** Jusqu'à ce nombre (inclus) → 1 pt ; au-delà → 0 pt. */
    public static final int ADJUSTMENT_HIGH_THRESHOLD = 4; // 2..4 → 1 pt, >4 → 0 pt

    // ── Décisions produit (fiche « à définir »/paramétrable) ─────────────────

    /**
     * {@code total_tasks} = 10–12. ⚠️ DÉCISION PRODUIT : la fiche ne fige pas le
     * nombre exact de tâches ; on retient une plage 10–12 (le critère le plus
     * lourd étant les dépendances).
     */
    public static final int TOTAL_TASKS_MIN = 10;
    public static final int TOTAL_TASKS_MAX = 12;

    /** {@code task_dependencies_enabled} = true (critère le plus lourd du barème). */
    public static final boolean TASK_DEPENDENCIES_ENABLED = true;

    /**
     * {@code time_constraints_mode} = « strict » (tout-ou-rien). ⚠️ DÉCISION
     * PRODUIT : la fiche ne détaille pas de mode partiel — à confirmer.
     */
    public static final String TIME_CONSTRAINTS_MODE = "strict";

    /**
     * Score du critère « réajustements » à partir du nombre BRUT :
     * {@code < 2 → 2 pts · 2..4 → 1 pt · > 4 → 0 pt}.
     *
     * @param adjustmentCount nombre brut de réajustements (>= 0)
     */
    public static int adjustmentScore(int adjustmentCount) {
        if (adjustmentCount < ADJUSTMENT_LOW_THRESHOLD) {
            return ADJUSTMENT_MAX_POINTS; // < 2 → 2 pts
        }
        if (adjustmentCount <= ADJUSTMENT_HIGH_THRESHOLD) {
            return 1; // 2 à 4 → 1 pt (⚠️ 2 inclus)
        }
        return 0; // > 4 → 0 pt
    }
}
