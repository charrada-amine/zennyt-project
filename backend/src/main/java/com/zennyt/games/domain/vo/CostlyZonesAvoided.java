package com.zennyt.games.domain.vo;

/**
 * Degré d'évitement des zones coûteuses sur un niveau « Chemin Optimal ».
 *
 * <p>La fiche parle d'« évitement total ou partiel » pour 2 pts max. Raffinement
 * implémenté (à valider par le psychologue) : {@code TOTAL}=2, {@code PARTIAL}=1,
 * {@code NONE}=0 (barème dans {@code OptimalPathConfig}).
 */
public enum CostlyZonesAvoided {
    TOTAL,
    PARTIAL,
    NONE
}
