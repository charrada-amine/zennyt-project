package com.zennyt.identity.domain;

import com.zennyt.identity.domain.model.AccountChangeCode;
import com.zennyt.identity.domain.model.AccountChangeType;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class AccountChangeCodeTest {

    private static final Instant NOW = Instant.parse("2026-09-11T12:00:00Z");

    @Test
    void aFreshCodeIsUsableAndNotConsumed() {
        AccountChangeCode code = AccountChangeCode.issue(1L, AccountChangeType.EMAIL,
            "new@example.com", "hash", NOW.plusSeconds(600));

        assertThat(code.usableAt(NOW)).isTrue();
        assertThat(code.consumedAt()).isNull();
        assertThat(code.attempts()).isZero();
        assertThat(code.target()).isEqualTo("new@example.com");
    }

    @Test
    void anExpiredCodeIsNotUsable() {
        AccountChangeCode code = AccountChangeCode.issue(1L, AccountChangeType.PHONE,
            "+33123456789", "hash", NOW.minusSeconds(1));

        assertThat(code.usableAt(NOW)).isFalse();
    }

    @Test
    void incrementingAttemptsAndConsumingKeepTheOtherFields() {
        AccountChangeCode code = AccountChangeCode.issue(1L, AccountChangeType.EMAIL,
            "new@example.com", "hash", NOW.plusSeconds(600));

        AccountChangeCode bumped = code.withIncrementedAttempts();
        assertThat(bumped.attempts()).isEqualTo(1);
        assertThat(bumped.target()).isEqualTo("new@example.com");

        AccountChangeCode consumed = bumped.consume();
        assertThat(consumed.consumedAt()).isNotNull();
        assertThat(consumed.usableAt(Instant.now())).isFalse();
    }
}
