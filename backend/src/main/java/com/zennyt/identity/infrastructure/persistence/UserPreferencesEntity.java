package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "user_preferences")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class UserPreferencesEntity {
    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "notifications_enabled", nullable = false)
    private boolean notificationsEnabled;

    @Column(name = "high_contrast", nullable = false)
    private boolean highContrast;

    @Column(name = "text_size_px", nullable = false)
    private int textSizePx;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
