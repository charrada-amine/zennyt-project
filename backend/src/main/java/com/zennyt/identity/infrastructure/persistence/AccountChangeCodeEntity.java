package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.AccountChangeType;
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
@Table(name = "account_change_codes",
    indexes = @Index(name = "idx_account_change_codes_user", columnList = "user_id, change_type"))
@Check(name = "ck_account_change_attempts", constraints = "attempts >= 0")
@Check(name = "ck_account_change_type", constraints = "change_type IN ('EMAIL', 'PHONE')")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AccountChangeCodeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "account_change_codes_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;

    @Enumerated(EnumType.STRING)
    @Column(name = "change_type", nullable = false, length = 10)
    private AccountChangeType changeType;

    @Column(name = "target", nullable = false, length = 150)
    private String target;

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

    AccountChangeCodeEntity(Long id, Long userId, AccountChangeType changeType, String target,
                            String codeHash, Instant expiresAt, Instant consumedAt, int attempts,
                            Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.changeType = changeType;
        this.target = target;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.consumedAt = consumedAt;
        this.attempts = attempts;
        this.createdAt = createdAt;
    }
}
