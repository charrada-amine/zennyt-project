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
    PENDING, SHORTLISTED, APPROVED, REJECTED;

    private static final Map<ApplicationStatus, Set<ApplicationStatus>> TRANSITIONS = Map.of(
        PENDING,      Set.of(SHORTLISTED, REJECTED),
        SHORTLISTED,  Set.of(APPROVED, REJECTED),
        APPROVED,     Set.of(),
        REJECTED,     Set.of()
    );

    public boolean canTransitionTo(ApplicationStatus target) {
        return TRANSITIONS.getOrDefault(this, Set.of()).contains(target);
    }
}
