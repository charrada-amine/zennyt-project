package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.BartPhase;

/**
 * Configuration <b>MOTEUR</b> du BART — Balloon Analogue Risk Task.
 *
 * <p>Source : Lejuez et al. (2002), <i>Journal of Experimental Psychology:
 * Applied</i>, 8(2), 75–84. Ce fichier ne contient que les valeurs du protocole
 * publié ; tout ce qui relève d'un choix de conception non validé (formule de
 * score, seuils de validité) vit dans {@link BartProvisionalRules}.
 *
 * <p>Revue scientifique complète : {@code docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md} §2.
 */
public final class BartConfig {

    private BartConfig() {
    }

    /** Version de protocole — fait partie de la graine de génération. */
    public static final String PROTOCOL_VERSION = "BART_LEJUEZ_V1";

    /** {@code practice_balloons} — ballons d'entraînement, jamais notés. */
    public static final int PRACTICE_BALLOON_COUNT = 2;

    /** {@code test_balloons} — 30 ballons notés (Lejuez 2002). */
    public static final int TEST_BALLOON_COUNT = 30;

    public static final int TOTAL_BALLOON_COUNT = PRACTICE_BALLOON_COUNT + TEST_BALLOON_COUNT;

    /**
     * {@code max_pumps} — le point d'éclatement est tiré uniformément sur
     * {@code 1..128} : la probabilité d'éclater à la pompe {@code k} vaut
     * {@code 1 / (128 − k + 1)}. Le ballon éclate SUR la pompe dont le numéro
     * égale son point d'éclatement ; au plus {@code point − 1} pompes sont sûres.
     */
    public static final int MAX_PUMPS = 128;

    /**
     * Points par pompe. Échelle d'affichage uniquement : le score est un ratio
     * (efficience), donc invariant à cette valeur. 1 point = maquette concept.
     */
    public static final int POINTS_PER_PUMP = 1;

    /** Phase d'un ballon d'après sa position dans la séquence (0-based). */
    public static BartPhase phaseOf(int balloonIndex) {
        if (balloonIndex < 0 || balloonIndex >= TOTAL_BALLOON_COUNT) {
            throw new IllegalArgumentException("Index de ballon hors protocole : " + balloonIndex);
        }
        return balloonIndex < PRACTICE_BALLOON_COUNT ? BartPhase.PRACTICE : BartPhase.TEST;
    }

    /**
     * Probabilité qu'un ballon survive à {@code pumps} pompes sous la loi uniforme :
     * {@code P(point > pumps) = (MAX_PUMPS − pumps) / MAX_PUMPS}.
     */
    public static double survivalProbability(int pumps) {
        if (pumps < 0 || pumps > MAX_PUMPS) {
            throw new IllegalArgumentException("Nombre de pompes hors bornes : " + pumps);
        }
        return (MAX_PUMPS - pumps) / (double) MAX_PUMPS;
    }

    /**
     * Stratégie fixe optimale en espérance : le nombre de pompes {@code n} qui
     * maximise {@code EV(n) = n × POINTS_PER_PUMP × (MAX_PUMPS − n) / MAX_PUMPS}.
     *
     * <p>Calculée, jamais codée en dur : elle vaut 64 pour {@code MAX_PUMPS = 128},
     * et un changement de loi la recalcule. C'est une propriété de la LOI, pas de
     * la séquence servie — le benchmark n'est pas clairvoyant.
     */
    public static int optimalFixedPumps() {
        int best = 0;
        double bestValue = -1.0;
        for (int n = 0; n < MAX_PUMPS; n++) {
            double value = n * survivalProbability(n);
            if (value > bestValue) {
                bestValue = value;
                best = n;
            }
        }
        return best;
    }
}
