package com.zennyt.games.domain.config;

import java.util.List;

/**
 * Configuration du mini-jeu « Predictive Puzzle » (Planifik #3 — Tour de Hanoï).
 *
 * <p>Java pur, sans Spring : invariantes métier issues de la fiche
 * « JE PLANIFIE — Mini-jeu 3 », <b>la seule fiche validée « aucune erreur,
 * conforme au script »</b>. Le barème est <b>catégoriel</b> (par critère) et non
 * une formule à pénalités.
 *
 * <p>Le barème est <b>calculé côté serveur</b> ({@code PlanifikScoringService})
 * à partir des métriques mesurées — le client n'envoie jamais de points. Le mock
 * mobile ({@code games_mock_repository.dart}) doit reproduire ces valeurs.
 */
public final class PrevisionPuzzleConfig {

    private PrevisionPuzzleConfig() {
    }

    // ── Clés techniques de la fiche ──────────────────────────────────────────

    /** {@code total_pegs} — nombre de tiges de la Tour de Hanoï. */
    public static final int TOTAL_PEGS = 3;

    /**
     * {@code puzzle_levels} — nombre de disques par niveau.
     *
     * <p>⚠️ DÉCISION PRODUIT (à valider) : la progression 3 → 4 → 5 disques est
     * un choix produit ; la fiche ne fige pas le nombre de niveaux.
     */
    public static final List<Integer> PUZZLE_LEVELS = List.of(3, 4, 5);

    /**
     * {@code max_sequence_errors} — tolérance d'erreurs de séquence par niveau.
     *
     * <p>⚠️ DÉCISION PRODUIT (à valider) : la fiche indique <b>3 (constant)</b>.
     * Le resserrement 3 → 2 → 1 (par niveau) est un choix produit — au-delà de la
     * tolérance, le niveau est en échec (voir 3.C).
     */
    public static final List<Integer> MAX_SEQUENCE_ERRORS = List.of(3, 2, 1);

    /** {@code preview_mode} — le joueur planifie/visualise toute la séquence avant exécution. */
    public static final boolean PREVIEW_MODE = true;

    /** {@code post_validation_edit} — édition du plan après validation interdite. */
    public static final boolean POST_VALIDATION_EDIT = false;

    /** {@code extra_moves_detection} — détection des coups superflus activée. */
    public static final boolean EXTRA_MOVES_DETECTION = true;

    // ── Poids du barème catégoriel (fiche : /10 par niveau) ──────────────────

    /** Points « séquence correcte au 1er essai » (first_try_sequence). */
    public static final int FIRST_TRY_POINTS = 4;

    /** Maximum du barème du mini-jeu (par niveau et agrégé). */
    public static final int MAX_POINTS = 10;

    // ── Calculs déterministes du barème ──────────────────────────────────────

    /** {@code optimal_moves(n) = 2^n − 1} — optimal déterministe (3→7, 4→15, 5→31). */
    public static int optimalMoves(int discCount) {
        return (1 << discCount) - 1;
    }

    /** Points « 1er essai » : réussite au 1er run sans retry ni erreur → 4, sinon 0. */
    public static int firstTryScore(boolean firstTrySuccess) {
        return firstTrySuccess ? FIRST_TRY_POINTS : 0;
    }

    /** Points « erreurs de séquence » : 0 → 3 · 1-2 → 2 · ≥3 → 1. */
    public static int sequenceErrorsScore(int sequenceErrors) {
        if (sequenceErrors <= 0) {
            return 3;
        }
        if (sequenceErrors <= 2) {
            return 2;
        }
        return 1;
    }

    /**
     * Points « mouvements superflus » selon le ratio
     * {@code (plannedMoves − optimalMoves) / optimalMoves} : &lt;10 % → 3 · &lt;25 % → 2 · ≥25 % → 1.
     */
    public static int extraMovesScore(int plannedMoves, int optimalMoves) {
        double ratio = optimalMoves <= 0
            ? 0.0
            : (plannedMoves - optimalMoves) / (double) optimalMoves;
        if (ratio < 0.10) {
            return 3;
        }
        if (ratio < 0.25) {
            return 2;
        }
        return 1;
    }

    /**
     * Score /10 d'un niveau = 1er essai + erreurs de séquence + mouvements superflus.
     * Un niveau échoué n'a <b>pas</b> de base forfaitaire : il est noté sur ses
     * compteurs réels (correction de la fiche — suppression de l'ancienne « base 4 »).
     */
    public static int levelScore(boolean firstTrySuccess, int sequenceErrors,
                                 int plannedMoves, int optimalMoves) {
        return firstTryScore(firstTrySuccess)
            + sequenceErrorsScore(sequenceErrors)
            + extraMovesScore(plannedMoves, optimalMoves);
    }

    /** Tolérance d'erreurs pour un niveau (fallback : dernière valeur si index hors bornes). */
    public static int maxSequenceErrorsForLevel(int levelIndex) {
        if (levelIndex >= 0 && levelIndex < MAX_SEQUENCE_ERRORS.size()) {
            return MAX_SEQUENCE_ERRORS.get(levelIndex);
        }
        return MAX_SEQUENCE_ERRORS.get(MAX_SEQUENCE_ERRORS.size() - 1);
    }
}
