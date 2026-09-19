package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "refresh_sessions",
    uniqueConstraints = @UniqueConstraint(name = "refresh_sessions_token_hash_key", columnNames = {"token_hash"}),
    indexes = @Index(name = "idx_refresh_sessions_user", columnList = "user_id"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RefreshSessionEntity {
    @Id
    private UUID id;
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "refresh_sessions_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;
    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "revoked_at")
    private Instant revokedAt;

    RefreshSessionEntity(UUID id, Long userId, String tokenHash, Instant expiresAt,
                         Instant createdAt, Instant revokedAt) {
        this.id = id;
        this.userId = userId;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
        this.revokedAt = revokedAt;
    }
}
