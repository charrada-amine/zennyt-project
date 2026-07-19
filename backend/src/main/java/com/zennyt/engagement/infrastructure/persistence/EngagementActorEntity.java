package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "actors", schema = "engagement")
class EngagementActorEntity {
    @Id @Column(name = "public_user_id") private UUID userId;
    @Column(nullable = false) private String role;
    @Column(nullable = false) private boolean active;
    private String displayName;
    @Column(columnDefinition = "TEXT") private String photoUrl;
    @Column(nullable = false) private Instant lastEventAt;
    @Column(nullable = false) private UUID lastEventId;

    protected EngagementActorEntity() {}

    EngagementActorEntity(UUID userId, String role, boolean active,
                          String displayName, String photoUrl,
                          Instant lastEventAt, UUID lastEventId) {
        this.userId = userId;
        this.role = role;
        this.active = active;
        this.displayName = displayName;
        this.photoUrl = photoUrl;
        this.lastEventAt = lastEventAt;
        this.lastEventId = lastEventId;
    }

    UUID getUserId() { return userId; }
    String getRole() { return role; }
    boolean isActive() { return active; }
    String getDisplayName() { return displayName; }
    String getPhotoUrl() { return photoUrl; }
    Instant getLastEventAt() { return lastEventAt; }
    UUID getLastEventId() { return lastEventId; }
}
