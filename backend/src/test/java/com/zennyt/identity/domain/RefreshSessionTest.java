package com.zennyt.identity.domain;

import com.zennyt.identity.domain.model.RefreshSession;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class RefreshSessionTest {
    @Test
    void revocationMakesSessionUnusable() {
        Instant now = Instant.now();
        RefreshSession session = RefreshSession.create(1L, "hash", now.plusSeconds(60));

        assertThat(session.usableAt(now)).isTrue();
        assertThat(session.revoke().usableAt(now)).isFalse();
    }
}
