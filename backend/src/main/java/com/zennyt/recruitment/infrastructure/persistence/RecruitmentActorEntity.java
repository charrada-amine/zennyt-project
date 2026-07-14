package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "actors", schema = "recruitment")
public class RecruitmentActorEntity {
    @Id
    @Column(name = "public_user_id", nullable = false)
    private UUID publicUserId;

    @Column(name = "role", nullable = false, length = 30)
    private String role;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "last_event_at", nullable = false)
    private Instant lastEventAt;

    @Column(name = "last_event_id", nullable = false)
    private UUID lastEventId;

    protected RecruitmentActorEntity() {}

    public RecruitmentActorEntity(UUID publicUserId, String role, boolean active,
                                  Instant lastEventAt, UUID lastEventId) {
        this.publicUserId = publicUserId;
        this.role = role;
        this.active = active;
        this.lastEventAt = lastEventAt;
        this.lastEventId = lastEventId;
    }

    public void apply(String role, boolean active, Instant eventAt, UUID eventId) {
        this.role = role;
        this.active = active;
        this.lastEventAt = eventAt;
        this.lastEventId = eventId;
    }

    public UUID getPublicUserId() { return publicUserId; }
    public String getRole() { return role; }
    public boolean isActive() { return active; }
    public Instant getLastEventAt() { return lastEventAt; }
    public UUID getLastEventId() { return lastEventId; }
}
