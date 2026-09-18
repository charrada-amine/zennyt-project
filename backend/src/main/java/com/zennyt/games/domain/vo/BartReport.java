package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Indicateurs BART dérivés côté serveur.
 *
 * <p>Deux familles, à ne jamais confondre :
 * <ul>
 *   <li><b>score</b> : {@code efficiencyPercent} — gains face au benchmark EV. Axe
 *       de performance : l'excès de prudence comme l'excès de risque coûtent.</li>
 *   <li><b>descriptif, non classé</b> : {@code adjustedAveragePumps} et les
 *       ajustements post-éclatement / post-collecte. Un TRAIT (appétence au risque) :
 *       aucun pôle n'est meilleur que l'autre.</li>
 * </ul>
 *
 * @param adjustedAveragePumps     moyenne des pompes sur les ballons notés COLLECTÉS
 *                                 seulement (les éclatés sont tronqués) ; null si aucun
 * @param evOptimalEarnings        gains de la stratégie fixe optimale sur la même séquence
 * @param meanPumpsAfterExplosion  pompes moyennes du ballon qui suit un éclatement ; null si aucun
 * @param meanPumpsAfterCollect    pompes moyennes du ballon qui suit une collecte ; null si aucune
 */
public record BartReport(
    String protocolVersion,
    boolean sessionValid,
    List<String> validityIssues,
    int testBalloonCount,
    int collectedCount,
    int explosionCount,
    Double adjustedAveragePumps,
    int totalEarnings,
    int evOptimalEarnings,
    int optimalFixedPumps,
    int efficiencyPercent,
    Double meanPumpsAfterExplosion,
    Double meanPumpsAfterCollect,
    Double medianInterPumpIntervalMs,
    List<BartBalloonReport> balloons
) {
    public BartReport {
        validityIssues = List.copyOf(validityIssues);
        balloons = List.copyOf(balloons);
    }
}
