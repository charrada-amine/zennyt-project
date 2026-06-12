package com.zennyt.recruitment.domain.vo;

import java.util.Set;
import java.util.Map;

/**
 * Statut d'une candidature et règles de transition autorisées.
 *
 * <p>La machine à états vit dans le domaine : c'est une invariante métier, pas
 * une règle d'infrastructure. Une transition interdite lève une exception
 * avant toute persistance.
 */
public enum ApplicationStatus {
    SUBMITTED, VIEWED, SHORTLISTED, INTERVIEW, OFFER, REJECTED, WITHDRAWN;

    private static final Map<ApplicationStatus, Set<ApplicationStatus>> TRANSITIONS = Map.of(
        SUBMITTED,   Set.of(VIEWED, REJECTED, WITHDRAWN),
        VIEWED,      Set.of(SHORTLISTED, REJECTED, WITHDRAWN),
        SHORTLISTED, Set.of(INTERVIEW, REJECTED, WITHDRAWN),
        INTERVIEW,   Set.of(OFFER, REJECTED, WITHDRAWN),
        OFFER,       Set.of(REJECTED, WITHDRAWN),
        REJECTED,    Set.of(),
        WITHDRAWN,   Set.of()
    );

    public boolean canTransitionTo(ApplicationStatus target) {
        return TRANSITIONS.getOrDefault(this, Set.of()).contains(target);
    }
}
