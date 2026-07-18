package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Projection locale minimale de l'état d'accès publié par Identity. */
public record EngagementActor(UUID userId, String role, boolean active,
                              String displayName, String photoUrl,
                              Instant lastEventAt, UUID lastEventId) {
    public EngagementActor {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(lastEventAt, "lastEventAt");
        Objects.requireNonNull(lastEventId, "lastEventId");
    }

    public EngagementActor apply(String nextRole, boolean nextActive,
                                 String nextDisplayName, String nextPhotoUrl,
                                 Instant eventAt, UUID eventId) {
        if (!lastEventAt.isBefore(eventAt) || lastEventId.equals(eventId)) return this;
        return new EngagementActor(userId, nextRole, nextActive,
            nextDisplayName, nextPhotoUrl, eventAt, eventId);
    }
}
