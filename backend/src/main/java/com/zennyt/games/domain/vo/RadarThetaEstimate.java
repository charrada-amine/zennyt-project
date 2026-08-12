package com.zennyt.games.domain.vo;

/**
 * Estimation du score décisionnel theta (type IRT) d'« Emotional Radar v2 ».
 *
 * <p>⚠️ <b>Usage décisionnel VERROUILLÉ.</b> Tant que {@code decisionalUseAllowed}
 * est {@code false} (calibration non « Validé »), ce score ne doit jamais servir à
 * comparer des personnes ni à des fins RH/cliniques. Il est calculé et exposé à titre
 * de <b>diagnostic</b> uniquement, avec un drapeau de fiabilité.
 *
 * @param theta                compétence estimée (échelle logit, ~[-3, 3])
 * @param standardError        erreur-type de l'estimation (dépend du nombre d'items)
 * @param itemsUsed            nombre d'items exploités
 * @param reliabilityFlag      « Fiable » ou « Provisoire »
 * @param decisionalUseAllowed autorisation d'usage décisionnel (false tant que non calibré)
 */
public record RadarThetaEstimate(
    double theta,
    double standardError,
    int itemsUsed,
    String reliabilityFlag,
    boolean decisionalUseAllowed
) {
}
