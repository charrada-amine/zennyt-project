package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.Score;

/**
 * Couche <b>PROVISOIRE</b> du BART — chaque valeur ici est un choix de conception
 * non validé par le psychologue référent. Le moteur ({@link BartConfig},
 * {@code BartScoringService}) lit ces valeurs et n'en code aucune.
 *
 * <p>Liste de validation : {@code docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md} §9.
 */
public final class BartProvisionalRules {

    private BartProvisionalRules() {
    }

    public static final int MAX_POINTS = 100;

    /** Aucune bande validée : libellé purement descriptif, comme « Je place ». */
    public static final String DESCRIPTIVE_LEVEL = "Descriptive — provisional";

    /**
     * PROVISOIRE — intervalle médian minimal entre deux pompes. En dessous, la
     * cadence n'est pas celle d'un doigt humain (automatisation ou double appui
     * systématique) et le run est invalide.
     */
    public static final double MIN_MEDIAN_INTER_PUMP_MS = 60.0;

    /**
     * PROVISOIRE — un run où TOUS les ballons notés reçoivent au plus ce nombre de
     * pompes n'est pas engagé dans la tâche (« collecte immédiate » ou « une seule
     * pompe systématiquement », design §8.1).
     */
    public static final int NON_ENGAGED_MAX_PUMPS = 1;

    /**
     * PROVISOIRE — score = efficience de gains face au benchmark EV, plafonnée à
     * 100, arrondie half-up une seule fois.
     *
     * <p>Construction propre à ce design, issue d'aucune publication (preuves §2.4).
     * Le plafond est nécessaire : un joueur chanceux peut dépasser le benchmark sur
     * une séquence donnée. Un benchmark nul (séquence dégénérée) n'est pas notable :
     * l'appelant marque alors le run invalide.
     */
    public static Score score(int totalEarnings, int evOptimalEarnings) {
        if (totalEarnings < 0 || evOptimalEarnings <= 0) {
            throw new IllegalArgumentException("Gains ou benchmark invalides");
        }
        int points = (int) Math.min(MAX_POINTS,
            (200L * totalEarnings + evOptimalEarnings) / (2L * evOptimalEarnings));
        return new Score(points, MAX_POINTS, DESCRIPTIVE_LEVEL);
    }
}
