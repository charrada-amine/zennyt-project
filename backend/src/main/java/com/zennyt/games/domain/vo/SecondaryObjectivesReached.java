package com.zennyt.games.domain.vo;

/**
 * Atteinte des objectifs secondaires sur un niveau « Chemin Optimal ».
 *
 * <p>Barème (dans {@code OptimalPathConfig}) : {@code YES}=1, {@code NO}=0 et
 * {@code PARTIAL}=règle à valider (0 ou 1 — voir
 * {@code OptimalPathConfig.SECONDARY_OBJECTIVE_PARTIAL_POINTS}).
 */
public enum SecondaryObjectivesReached {
    YES,
    PARTIAL,
    NO
}
