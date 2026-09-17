package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.CopingFamily;
import com.zennyt.games.domain.vo.StrategicChoiceStrategy;

/**
 * Barème « Choix Stratégiques ».
 *
 * <p>Chaque situation cote ses huit stratégies de 0 à 3 — 3 la plus pertinente,
 * 0 contre-productive. Le score d'une partie est la somme des cotations
 * retenues, sur un maximum de {@code situations × 3}. Le maximum est donc
 * DYNAMIQUE, comme pour Emotional Radar : il suit le nombre de situations
 * réellement jouées plutôt qu'un total figé dans l'énumération des mini-jeux.
 *
 * <p><b>Seuils d'interprétation.</b> Posés en pourcentage du maximum. Sur
 * l'ensemble de la banque, cocher toujours « Assertive communication » rapporte
 * 1,94/3 de moyenne, contre 1,19 au hasard et 2,99 pour un jeu parfait. Après
 * correction du hasard, cette conduite constante vaut environ 41 % : le palier
 * haut à 60 % reste donc hors de portée EN MOYENNE.
 *
 * <p>⚠️ Il ne l'est pas sur un tirage donné, et aucun seuil ne pourrait le
 * rendre tel. « Assertive communication » vaut 3 dans 28 fiches sur 80 : un
 * tirage de dix qui tombe dessus donne 30/30 à un joueur qui n'a rien lu. Le
 * garde-fou n'est pas le seuil mais le rapport, qui compte les stratégies
 * réellement mobilisées — une partie entière menée avec une seule stratégie s'y
 * lit noir sur blanc. C'est une limite du barème du client, pas du calcul.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : le mock Dart reproduit exactement ce calcul.
 */
public final class StrategicChoicesConfig {

    /**
     * Correspondance des huit stratégies du client avec les familles de Carver.
     *
     * <p>Cinq sont univoques — « Humor » est même l'intitulé exact d'une échelle
     * du Brief COPE. Deux ne le sont pas et restent {@link CopingFamily#UNRESOLVED}
     * plutôt que d'être rangées de force : voir la documentation de cette
     * constante.
     */
    public static CopingFamily familyOf(StrategicChoiceStrategy strategy) {
        return switch (strategy) {
            // active coping / planning
            case ASSERTIVE_COMMUNICATION, DIRECT_ACTION -> CopingFamily.PROBLEM_FOCUSED;
            // positive reframing / humor
            case COGNITIVE_REAPPRAISAL, HUMOR -> CopingFamily.EMOTION_FOCUSED;
            // behavioral disengagement / venting, self-blame
            case AVOID_FLEE, RUMINATE -> CopingFamily.DYSFUNCTIONAL;
            // soutien émotionnel OU instrumental ; modulation de la réponse
            case SEEK_SUPPORT, BREATHE_PAUSE -> CopingFamily.UNRESOLVED;
        };
    }


    private StrategicChoicesConfig() {
    }

    /** Cotation maximale d'une stratégie sur une situation. */
    public static final int MAX_POINTS_PER_SITUATION = 3;

    /** Nombre de situations attendues dans une partie. */
    public static final int SITUATIONS_PER_JOURNEY = 10;

    /** Seuils sur l'indice CORRIGÉ du hasard — voir {@link #interpret(double)}. */
    public static final double ADAPTIVE_THRESHOLD_PERCENT = 25.0;
    public static final double HIGHLY_ADAPTIVE_THRESHOLD_PERCENT = 60.0;

    public static int maxPointsFor(int situations) {
        return situations * MAX_POINTS_PER_SITUATION;
    }

    /**
     * Indice corrigé du hasard, en pourcentage.
     *
     * <p>{@code (obtenu - hasard) / (maximum - hasard)}. Le score brut seul ne
     * veut rien dire : répondre au hasard rapporte déjà <b>40 %</b> du maximum,
     * parce que la plupart des stratégies sont cotées 1 ou 2. Un joueur à 50 %
     * brut est donc à peine au-dessus du bruit.
     *
     * <p>La ligne de base est calculée sur les situations RÉELLEMENT tirées —
     * somme des moyennes des huit cotations de chaque fiche — et non sur la
     * banque entière : un tirage facile relève la barre avec lui.
     *
     * <p>Plancher à 0 : « moins bien que le hasard » n'est pas une performance
     * négative, c'est du bruit.
     */
    public static double chanceCorrectedPercent(
            int rawPoints, int maxPoints, double chanceBaseline) {
        double range = maxPoints - chanceBaseline;
        if (range <= 0) {
            return 0.0;
        }
        return Math.max(0.0, (rawPoints - chanceBaseline) * 100.0 / range);
    }

    /**
     * Interprétation, sur l'indice CORRIGÉ et non sur le pourcentage brut.
     *
     * <p>Seuils justifiés par la distribution mesurée sur 4 000 tirages
     * simulés : le hasard vaut 0 par construction, et cocher toujours la
     * stratégie la mieux cotée de la banque (« Assertive communication ») donne
     * environ 41 % en moyenne. Le palier haut est donc placé à 60 %, au-dessus de ce
     * qu'une stratégie constante rapporte ; en dessous de 25 %, on ne se
     * distingue pas du hasard.
     */
    public static String interpret(double chanceCorrectedPercent) {
        if (chanceCorrectedPercent >= HIGHLY_ADAPTIVE_THRESHOLD_PERCENT) {
            return "Highly adaptive strategies";
        }
        if (chanceCorrectedPercent >= ADAPTIVE_THRESHOLD_PERCENT) {
            return "Adaptive strategies";
        }
        return "Reactive strategies";
    }
}
