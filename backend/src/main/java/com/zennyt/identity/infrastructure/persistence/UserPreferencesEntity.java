package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Entity
@Table(name = "user_preferences")
@Check(name = "ck_user_preferences_text_size", constraints = "text_size_px >= 10 AND text_size_px <= 30")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserPreferencesEntity {
    @Id
    @Column(name = "user_id")
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "user_preferences_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;

    @ColumnDefault("true")
    @Column(name = "notifications_enabled", nullable = false)
    private boolean notificationsEnabled;

    @ColumnDefault("true")
    @Column(name = "high_contrast", nullable = false)
    private boolean highContrast;

    @ColumnDefault("18")
    @Column(name = "text_size_px", nullable = false)
    private int textSizePx;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public UserPreferencesEntity(Long userId, boolean notificationsEnabled, boolean highContrast,
                                 int textSizePx, Instant updatedAt) {
        this.userId = userId;
        this.notificationsEnabled = notificationsEnabled;
        this.highContrast = highContrast;
        this.textSizePx = textSizePx;
        this.updatedAt = updatedAt;
    }
}
