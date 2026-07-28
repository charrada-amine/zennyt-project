package com.zennyt.games.domain.config;

import java.util.List;

/**
 * Barème d'« Emotional Radar » (GameType EMOTIONAL_REGULATION, régulation émotionnelle).
 *
 * <p>Java pur, sans Spring. Constantes issues de la planche « Developer handoff »
 * (carte <i>Scoring</i>). Le score est <b>calculé côté serveur</b> à partir des
 * réponses notées et persistées scène par scène — le client n'envoie jamais de
 * points. Le mock mobile ({@code games_mock_repository.dart}) reproduit ce barème
 * à l'identique ; toute modification ici impose la même modification là-bas
 * (AGENTS.md §7.7).
 *
 * <p><b>Barème par scène — total 9 points :</b>
 * <ul>
 *   <li>émotion de base exacte → {@value #EMOTION_POINTS} pts, sinon 0 ;</li>
 *   <li>nuance exacte → {@value #NUANCE_POINTS} pts, sinon 0 ;</li>
 *   <li>intensité : écart 0 → {@value #INTENSITY_POINTS} pts · écart 1 → 1 pt ·
 *       écart ≥ 2 → 0.</li>
 * </ul>
 *
 * <p>Les deux totaux annoncés par la maquette se recoupent exactement :
 * 9 × 3 = <b>27</b> (échantillon Phase 2) et 9 × 15 = <b>135</b> (jeu complet).
 */
public final class EmotionalRadarConfig {

    private EmotionalRadarConfig() {
    }

    // ── Barème par scène (planche « Developer handoff », carte Scoring) ───────

    /** {@code basic_emotion} — famille exacte, tout ou rien. */
    public static final int EMOTION_POINTS = 3;

    /** {@code nuance} — nuance exacte, tout ou rien. */
    public static final int NUANCE_POINTS = 4;

    /** {@code intensity} — points maximum du critère d'intensité. */
    public static final int INTENSITY_POINTS = 2;

    /** Total par scène sans bonus : 3 + 4 + 2 = 9. */
    public static final int POINTS_PER_SCENE =
        EMOTION_POINTS + NUANCE_POINTS + INTENSITY_POINTS;

    /**
     * {@code gradient_bonus} — « +1 optional » sur la maquette.
     *
     * <p>⚠️ <b>DÉSACTIVÉ par défaut — décision produit tracée.</b> L'activer porterait
     * le maximum à 10 points par scène, ce qui contredirait les <i>deux</i> totaux
     * affichés par la maquette (27 pour 3 scènes, 135 pour 15). De plus, le VO
     * {@code Score} rejette {@code rawPoints > maxPoints}. Basculer ce drapeau (et son
     * miroir mobile) suffit à l'activer, sans refactor.
     */
    public static final boolean GRADIENT_BONUS_ENABLED = false;

    /** Points du bonus de gradient lorsqu'il est activé. */
    public static final int GRADIENT_BONUS_POINTS = 1;

    // ── Échelle d'intensité (écran « 3 Intensity ») ──────────────────────────

    public static final int MIN_INTENSITY = 1;
    public static final int MAX_INTENSITY = 5;

    /** Libellés des 5 niveaux, dans l'ordre (maquette : Weak → Very strong). */
    public static final List<String> INTENSITY_LABELS =
        List.of("Weak", "Low", "Moderate", "Strong", "Very strong");

    /**
     * {@code total_scenes} — nombre de scènes d'une session.
     *
     * <p>⚠️ <b>Décision produit à valider.</b> La maquette affiche « Scene N / 15 »,
     * mais seules <b>3</b> scènes sont rédigées dans le handoff, et la planche
     * « Phase 2 QA notes » place explicitement le contenu des 15 scènes en Phase 3.
     * Aucune scène n'est inventée : la valeur suivra la livraison du psychologue.
     */
    public static final int TOTAL_SCENES = 3;

    /**
     * Points du critère d'intensité selon l'écart à l'intensité attendue.
     *
     * <p>La maquette ne fixe que « Intensity 2 pts ». Le dégradé 2/1/0 traduit la
     * notion de « calibration quality » affichée sur la planche des états
     * (« 81% Intensity — Calibration quality ») : une intensité voisine vaut mieux
     * qu'une intensité aberrante. ⚠️ À valider par le psychologue.
     */
    public static int intensityScore(int expected, int selected) {
        int gap = Math.abs(expected - selected);
        if (gap == 0) {
            return INTENSITY_POINTS;
        }
        if (gap == 1) {
            return 1;
        }
        return 0;
    }

    /** Maximum du mini-jeu pour un nombre de scènes jouées (barème dynamique). */
    public static int maxPointsFor(int scenesPlayed) {
        int perScene = POINTS_PER_SCENE
            + (GRADIENT_BONUS_ENABLED ? GRADIENT_BONUS_POINTS : 0);
        return Math.max(1, scenesPlayed) * perScene;
    }
}
