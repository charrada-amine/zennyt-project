package com.zennyt.recruitment.domain.vo;

import java.util.Map;
import java.util.Set;

/**
 * Statut d'une offre d'emploi et règles de transition.
 *
 * <p>Machine à états : DRAFT → ACTIVE → HIDDEN → CLOSED.
 * Seul le recruteur propriétaire peut changer le statut.
 */
public enum JobOfferStatus {
    DRAFT, ACTIVE, HIDDEN, CLOSED;

    private static final Map<JobOfferStatus, Set<JobOfferStatus>> TRANSITIONS = Map.of(
        DRAFT,   Set.of(ACTIVE),
        ACTIVE,  Set.of(HIDDEN, CLOSED),
        HIDDEN,  Set.of(ACTIVE, CLOSED),
        CLOSED,  Set.of()
    );

    public boolean canTransitionTo(JobOfferStatus target) {
        return TRANSITIONS.getOrDefault(this, Set.of()).contains(target);
    }
}
