package com.zennyt.recruitment.domain.event;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand le statut d'une candidature change (PENDING → SHORTLISTED → APPROVED/REJECTED). */
public record ApplicationStatusChangedEvent(
    UUID eventId, Instant occurredAt,
    UUID applicationId, UUID candidateId, UUID jobOfferId, UUID recruiterId, String jobTitle,
    ApplicationStatus previousStatus, ApplicationStatus newStatus
) implements DomainEvent {

    public static ApplicationStatusChangedEvent of(UUID applicationId, UUID candidateId, UUID jobOfferId,
                                                   UUID recruiterId, String jobTitle,
                                                   ApplicationStatus previous, ApplicationStatus newStatus) {
        return new ApplicationStatusChangedEvent(UUID.randomUUID(), Instant.now(),
            applicationId, candidateId, jobOfferId, recruiterId, jobTitle, previous, newStatus);
    }

    @Override public String eventType() { return "recruitment.application.status_changed"; }
}
