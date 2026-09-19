package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Entity
@Table(name = "password_reset_codes",
    indexes = @Index(name = "idx_password_reset_codes_user", columnList = "user_id"))
@Check(name = "ck_password_reset_attempts", constraints = "attempts >= 0")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PasswordResetCodeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "password_reset_codes_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;
    @Column(name = "code_hash", nullable = false, length = 64)
    private String codeHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "consumed_at")
    private Instant consumedAt;
    @ColumnDefault("0")
    @Column(name = "attempts", nullable = false)
    private int attempts;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    PasswordResetCodeEntity(Long id, Long userId, String codeHash, Instant expiresAt,
                            Instant consumedAt, int attempts, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.consumedAt = consumedAt;
        this.attempts = attempts;
        this.createdAt = createdAt;
    }
}
