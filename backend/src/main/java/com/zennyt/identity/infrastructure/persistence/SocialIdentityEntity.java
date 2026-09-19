package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.SocialProvider;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Entity
@Table(name = "social_identities",
    uniqueConstraints = {
        @UniqueConstraint(name = "uq_social_identities_provider_subject", columnNames = {"provider", "provider_subject"}),
        @UniqueConstraint(name = "uq_social_identities_user_provider", columnNames = {"user_id", "provider"})},
    indexes = @Index(name = "idx_social_identities_user", columnList = "user_id"))
@Check(name = "ck_social_identities_provider", constraints = "provider IN ('GOOGLE', 'APPLE')")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SocialIdentityEntity {
    @Getter(AccessLevel.PACKAGE)
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "social_identities_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;

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
}
