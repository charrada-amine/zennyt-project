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

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "city")
    private String city;

    @Column(name = "country")
    private String country;

    @Column(name = "last_event_at", nullable = false)
    private Instant lastEventAt;

    @Column(name = "last_event_id", nullable = false)
    private UUID lastEventId;

    protected RecruitmentActorEntity() {}

    public RecruitmentActorEntity(UUID publicUserId, String role, boolean active,
                                  String fullName, String avatarUrl, String city, String country,
                                  Instant lastEventAt, UUID lastEventId) {
        this.publicUserId = publicUserId;
        this.role = role;
        this.active = active;
        this.fullName = fullName;
        this.avatarUrl = avatarUrl;
        this.city = city;
        this.country = country;
        this.lastEventAt = lastEventAt;
        this.lastEventId = lastEventId;
    }

    public void apply(String role, boolean active, String fullName, String avatarUrl,
                      String city, String country, Instant eventAt, UUID eventId) {
        this.role = role;
        this.active = active;
        this.fullName = fullName;
        this.avatarUrl = avatarUrl;
        this.city = city;
        this.country = country;
        this.lastEventAt = eventAt;
        this.lastEventId = eventId;
    }

    public UUID getPublicUserId() { return publicUserId; }
    public String getRole() { return role; }
    public boolean isActive() { return active; }
    public String getFullName() { return fullName; }
    public String getAvatarUrl() { return avatarUrl; }
    public String getCity() { return city; }
    public String getCountry() { return country; }
    public Instant getLastEventAt() { return lastEventAt; }
    public UUID getLastEventId() { return lastEventId; }
}
