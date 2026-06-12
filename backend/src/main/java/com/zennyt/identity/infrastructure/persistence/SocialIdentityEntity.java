package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.SocialProvider;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "social_identities")
public class SocialIdentityEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SocialProvider provider;

    @Column(name = "provider_subject", nullable = false, length = 255)
    private String providerSubject;

    @Column(length = 150)
    private String email;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected SocialIdentityEntity() {}

    SocialIdentityEntity(Long id, Long userId, SocialProvider provider, String providerSubject,
                         String email, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.provider = provider;
        this.providerSubject = providerSubject;
        this.email = email;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    Long getId() { return id; }
    Long getUserId() { return userId; }
    SocialProvider getProvider() { return provider; }
    String getProviderSubject() { return providerSubject; }
    String getEmail() { return email; }
    Instant getCreatedAt() { return createdAt; }
    Instant getUpdatedAt() { return updatedAt; }
}
