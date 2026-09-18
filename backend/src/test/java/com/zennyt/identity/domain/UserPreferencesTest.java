package com.zennyt.identity.domain;

import com.zennyt.identity.domain.model.UserPreferences;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UserPreferencesTest {

    @Test
    void defaultsAreNotificationsOnContrastOnAnd18px() {
        UserPreferences preferences = UserPreferences.defaults(42L);

        assertThat(preferences.userId()).isEqualTo(42L);
        assertThat(preferences.notificationsEnabled()).isTrue();
        assertThat(preferences.highContrast()).isTrue();
        assertThat(preferences.textSizePx()).isEqualTo(18);
        assertThat(preferences.updatedAt()).isNotNull();
    }

    @Test
    void textSizeOutsideTheDesignRangeIsRejected() {
        assertThatThrownBy(() -> new UserPreferences(1L, true, true, 9, Instant.now()))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new UserPreferences(1L, true, true, 31, Instant.now()))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void withKeepsTheAccountAndAppliesTheNewValues() {
        Instant now = Instant.parse("2026-09-11T12:00:00Z");
        UserPreferences updated = UserPreferences.defaults(7L).with(false, false, 24, now);

        assertThat(updated.userId()).isEqualTo(7L);
        assertThat(updated.notificationsEnabled()).isFalse();
        assertThat(updated.highContrast()).isFalse();
        assertThat(updated.textSizePx()).isEqualTo(24);
        assertThat(updated.updatedAt()).isEqualTo(now);
    }
}
