package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.Score;

/**
 * Couche <b>PROVISOIRE</b> de l'IST — chaque valeur ici est un choix de conception
 * non validé par le psychologue référent.
 *
 * <p>Liste de validation : {@code docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md} §9.
 */
public final class IstProvisionalRules {

    private IstProvisionalRules() {
    }

    public static final int MAX_POINTS = 100;
    public static final String DESCRIPTIVE_LEVEL = "Descriptive — provisional";

    // ── Loi de génération des grilles — SOURCE UNIQUE ─────────────────────────
    //
    // Le générateur tire le nombre de cases bleues dans cette loi, et le calcul de
    // P(correct) l'utilise comme a priori. Les deux lisent ces constantes, jamais
    // une copie : c'est ce qui rend P(correct) EXACT pour notre tâche.
    //
    // Contexte : le calcul conventionnel de P(correct) est contesté (Bennett et al.
    // 2017, Biol. Psychiatry 82(4) e29-e30 ; Axelsen, Jepsen & Bak 2018, Biol.
    // Psychiatry 83(12) e59-e60, et réponse). Le désaccord porte sur l'A PRIORI.
    // Nous générons nous-mêmes les grilles : l'a priori exact est donc connu, et le
    // postérieur calculé sous cet a priori est correct par construction. Le texte
    // intégral de Bennett et al. n'a pas pu être obtenu (accès payant) ; ce choix
    // est à confirmer par le psychologue (preuves §3.3, §9).

    /**
     * PROVISOIRE — la couleur majoritaire occupe entre 13 et 19 cases sur 25, tirage
     * uniforme, couleur majoritaire tirée à pile ou face. Écarte les grilles
     * écrasantes (20+ cases) où une seule case suffit à décider, qui ne mesurent
     * rien de la réflexion.
     */
    public static final int MAJORITY_COUNT_MIN = 13;
    public static final int MAJORITY_COUNT_MAX = 19;

    /** Nombre de cases bleues possibles : {@code 6..19} (symétrique autour de 12,5). */
    public static final int BLUE_COUNT_MIN = IstConfig.BOX_COUNT - MAJORITY_COUNT_MAX;
    public static final int BLUE_COUNT_MAX = MAJORITY_COUNT_MAX;

    /** Loi a priori sur le nombre de cases bleues, indexée 0..25. Somme = 1. */
    public static double[] blueCountPrior() {
        double[] prior = new double[IstConfig.BOX_COUNT + 1];
        int support = BLUE_COUNT_MAX - BLUE_COUNT_MIN + 1;
        for (int k = BLUE_COUNT_MIN; k <= BLUE_COUNT_MAX; k++) {
            prior[k] = 1.0 / support;
        }
        return prior;
    }

    // ── Score ────────────────────────────────────────────────────────────────

    /** PROVISOIRE — poids de l'exactitude des décisions notées. */
    public static final double ACCURACY_WEIGHT = 0.4;

    /** PROVISOIRE — poids de la preuve détenue au moment de décider. */
    public static final double EVIDENCE_WEIGHT = 0.4;

    /** PROVISOIRE — poids de l'ajustement de l'échantillonnage à son coût. */
    public static final double DISCRIMINATION_WEIGHT = 0.2;

    /**
     * PROVISOIRE — écart de cases ouvertes (gain fixe − gain décroissant) qui vaut
     * la note pleine de discrimination. 5 cases ≈ un cinquième de la grille.
     */
    public static final double DISCRIMINATION_REFERENCE_BOXES = 5.0;

    /**
     * PROVISOIRE — score /100 :
     * {@code 100 × (0,4 × exactitude + 0,4 × preuve + 0,2 × discrimination)}, chaque
     * composante bornée à [0, 1], un seul arrondi half-up.
     *
     * @param accuracy       part de décisions justes, 0..1
     * @param meanPCorrect   P(correct) moyen à la décision, 0..1 (0,5 = hasard)
     * @param boxesFixedWin  cases ouvertes en moyenne, gain fixe
     * @param boxesDecreasingWin cases ouvertes en moyenne, gain décroissant
     */
    public static Score score(double accuracy, double meanPCorrect,
                              double boxesFixedWin, double boxesDecreasingWin) {
        double evidence = clamp01((meanPCorrect - 0.5) / 0.5);
        double discrimination = clamp01(
            (boxesFixedWin - boxesDecreasingWin) / DISCRIMINATION_REFERENCE_BOXES);
        double weighted = ACCURACY_WEIGHT * clamp01(accuracy)
            + EVIDENCE_WEIGHT * evidence
            + DISCRIMINATION_WEIGHT * discrimination;
        int points = (int) Math.floor(100.0 * weighted + 0.5);
        return new Score(Math.min(MAX_POINTS, points), MAX_POINTS, DESCRIPTIVE_LEVEL);
    }

    // ── Validité de session ──────────────────────────────────────────────────

    /** PROVISOIRE — intervalle médian minimal entre deux actions (ouverture ou décision). */
    public static final double MIN_MEDIAN_INTER_ACTION_MS = 80.0;

    /**
     * PROVISOIRE — une décision est « aléatoire » si la couleur choisie avait au
     * plus cette probabilité d'être majoritaire au vu des cases ouvertes.
     */
    public static final double RANDOM_RESPONSE_MAX_P_CORRECT = 0.1;

    /** PROVISOIRE — au-delà de ce taux de décisions aléatoires, le run est invalide. */
    public static final double MAX_RANDOM_RESPONSE_RATE = 0.3;

    // ── Couche confiance ─────────────────────────────────────────────────────

    /** Échelle à 4 points, sans milieu : 1 = au hasard … 4 = certain. */
    public static final int CONFIDENCE_MIN = 1;
    public static final int CONFIDENCE_MAX = 4;

    /**
     * PROVISOIRE — probabilité subjective associée à chaque point de l'échelle,
     * équirépartie sur [0,5 ; 1] : au hasard = 0,5 · plutôt sûr = 2/3 · sûr = 5/6 ·
     * certain = 1.
     *
     * <p>Corrige le défaut initial du design (0,625 / 0,75 / 0,875 / 1,0), qui
     * attribuait 62,5 % au libellé « au hasard » : un choix binaire fait au hasard
     * vaut 50 %, et le biais de calibration en aurait été décalé vers la
     * surconfiance pour tous les candidats.
     */
    public static double confidenceProbability(int confidence) {
        if (confidence < CONFIDENCE_MIN || confidence > CONFIDENCE_MAX) {
            throw new IllegalArgumentException("Confiance hors échelle : " + confidence);
        }
        return 0.5 + 0.5 * (confidence - CONFIDENCE_MIN) / (CONFIDENCE_MAX - CONFIDENCE_MIN);
    }

    private static double clamp01(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }
}
