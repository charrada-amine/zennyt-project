package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Projection locale de candidature dans le contexte Engagement.
 *
 * <p>Alimentée par {@code ApplicationSubmittedEvent} (Recruitment), elle porte le
 * strict nécessaire pour (re)construire une conversation sans appel direct au
 * module Recruitment. Read model applicatif, agnostique du framework.
 */
public record EngagementApplication(UUID applicationId, UUID jobOfferId, UUID candidateId,
                                    UUID recruiterId, String jobTitle,
                                    UUID lastEventId, Instant lastEventAt) {
    public EngagementApplication {
        Objects.requireNonNull(applicationId, "applicationId");
        Objects.requireNonNull(jobOfferId, "jobOfferId");
        Objects.requireNonNull(candidateId, "candidateId");
        Objects.requireNonNull(recruiterId, "recruiterId");
        Objects.requireNonNull(lastEventId, "lastEventId");
        Objects.requireNonNull(lastEventAt, "lastEventAt");
    }

    public boolean hasParticipant(UUID userId) {
        return candidateId.equals(userId) || recruiterId.equals(userId);
    }
}
