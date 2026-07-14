package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/** Projection minimale de l'état d'accès Identity, sans PII. */
public record RecruitmentActor(
    UUID publicUserId,
    String role,
    boolean active,
    Instant lastEventAt,
    UUID lastEventId
) {
    public RecruitmentActor apply(String newRole, boolean newActive,
                                  Instant eventAt, UUID eventId) {
        return new RecruitmentActor(publicUserId, newRole, newActive, eventAt, eventId);
    }
}
