package com.zennyt.games.domain.config;

import java.util.List;

/**
 * Configuration du mini-jeu « Chemin Optimal » (Planifik #1 — Planification).
 *
 * <p>Java pur, sans Spring : invariantes métier issues de la fiche
 * « JE PLANIFIE — Mini-jeu 1 ». Les constantes sont nommées d'après les clés
 * techniques de la fiche pour tracer la correspondance fiche ⇄ code.
 *
 * <p>Le barème est <b>calculé côté serveur</b> ({@code PlanifikScoringService})
 * à partir des métriques mesurées — le client n'envoie jamais de points. Le mock
 * mobile ({@code games_mock_repository.dart}) doit reproduire ces valeurs.
 */
public final class OptimalPathConfig {

    private OptimalPathConfig() {
    }

    // ── Clés techniques de la fiche ──────────────────────────────────────────

    /** {@code optimal_path_tolerance} — ±10 % pour accorder les 4 pts « respect du chemin optimal ». */
    public static final double OPTIMAL_PATH_TOLERANCE = 0.10;

    /** {@code max_attempts} — plafond du barème « nombre d'essais » (1→3 pts, 2→2 pts, ≥3→1 pt). */
    public static final int MAX_ATTEMPTS = 3;

    /**
     * {@code total_levels} — nombre de niveaux jouables.
     *
     * <p>⚠️ DÉCISION PRODUIT : la fiche indique « à définir ». La valeur 4
     * (4 niveaux randomisés par graphe BFS côté mobile) est un choix produit
     * assumé, à confirmer avec le psychologue référent le cas échéant.
     */
    public static final int TOTAL_LEVELS = 4;

    /** {@code preplanning_required} — le joueur doit planifier son chemin avant validation. */
    public static final boolean PREPLANNING_REQUIRED = true;

    /** {@code global_plan_validation} — le plan est validé globalement (et non coup par coup). */
    public static final boolean GLOBAL_PLAN_VALIDATION = true;

    // ── Poids du barème (fiche : 4 + 3 + 2 + 1 = /10) ────────────────────────

    /** Points « respect du chemin optimal » (dans la tolérance). */
    public static final int OPTIMAL_PATH_POINTS = 4;

    /** Points « évitement des zones coûteuses » — évitement TOTAL. */
    public static final int COSTLY_ZONES_POINTS = 2;

    /**
     * Points « évitement des zones coûteuses » — évitement PARTIEL.
     *
     * <p>⚠️ RAFFINEMENT À VALIDER : la fiche dit « évitement total ou partiel »
     * pour 2 pts max. Choix implémenté TOTAL=2 / PARTIAL=1 / NONE=0 — à confirmer
     * avec le psychologue référent.
     */
    public static final int COSTLY_ZONES_PARTIAL_POINTS = 1;

    /** Points « objectifs secondaires atteints » — atteinte complète (YES). */
    public static final int SECONDARY_OBJECTIVE_POINTS = 1;

    /**
     * Points « objectifs secondaires » — atteinte PARTIELLE.
     *
     * <p>⚠️ RÈGLE À VALIDER : la fiche ne tranche pas le cas partiel. Choix
     * implémenté PARTIAL=0 (seule l'atteinte complète accorde le point) — à
     * confirmer avec le psychologue référent (basculer à 1 si nécessaire).
     */
    public static final int SECONDARY_OBJECTIVE_PARTIAL_POINTS = 0;

    /** Maximum du barème du mini-jeu. */
    public static final int MAX_POINTS = 10;

    /**
     * Points du critère « nombre d'essais » : 1 essai = {@link #MAX_ATTEMPTS} pts,
     * puis −1 point par essai supplémentaire, plancher 1 point.
     *
     * @param attempts nombre d'essais avant validation (≥ 1)
     */
    public static int attemptScore(int attempts) {
        return Math.max(1, MAX_ATTEMPTS + 1 - Math.min(attempts, MAX_ATTEMPTS));
    }

    // ── Interprétation /10 par mini-jeu (bandes provisoires) ─────────────────

    /** Bande d'interprétation : niveau attribué si {@code points >= minInclusive}. */
    public record InterpretationBand(int minInclusive, String level) {
    }

    /**
     * Bandes d'interprétation /10 d'un mini-jeu Planifik (0–3 / 4–6 / 7–10).
     *
     * <p>// AJOUT NON VALIDÉ PAR LE PSYCHOLOGUE — bandes provisoires.
     * Ces seuils par mini-jeu sont un ajout développeur (la fiche ne définit que
     * les bandes du profil GLOBAL /30, elles conformes et non modifiées ici).
     * Partagées avec « Predictive Puzzle ». À valider ou remplacer.
     */
    public static final List<InterpretationBand> MINI_GAME_INTERPRETATION_BANDS = List.of(
        new InterpretationBand(7, "Bon à excellent"),
        new InterpretationBand(4, "Moyen"),
        new InterpretationBand(0, "Très faible")
    );

    /** Interprète un score /10 de mini-jeu selon les bandes provisoires ci-dessus. */
    public static String interpretMiniGame(int points) {
        return MINI_GAME_INTERPRETATION_BANDS.stream()
            .filter(band -> points >= band.minInclusive())
            .map(InterpretationBand::level)
            .findFirst()
            .orElse("Très faible");
    }
}
