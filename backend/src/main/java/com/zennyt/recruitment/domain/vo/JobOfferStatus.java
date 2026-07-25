package com.zennyt.recruitment.domain.vo;

/**
 * Statut d'une offre d'emploi.
 *
 * <p>Librement réversible dans n'importe quelle direction, aucun état terminal
 * (contrat squad web, §3.1 — "freely reversible, no terminal state").
 * Seul le recruteur propriétaire peut changer le statut.
 */
public enum JobOfferStatus {
    DRAFT, ACTIVE, CLOSED;

    public boolean canTransitionTo(JobOfferStatus target) {
        return true;
    }
}
