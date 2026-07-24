package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.EngagementActor;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class EngagementActorTest {

    @Test
    void newer_access_state_replaces_the_projection() {
        EngagementActor actor = new EngagementActor(
            UUID.randomUUID(), "CANDIDATE", true, "Ada", null,
            Instant.parse("2026-07-18T08:00:00Z"), UUID.randomUUID());

        EngagementActor applied = actor.apply(
            "RECRUITER", false, "Grace", "https://img.test/grace", Instant.parse("2026-07-18T09:00:00Z"), UUID.randomUUID());

        assertEquals("RECRUITER", applied.role());
        assertFalse(applied.active());
        assertEquals("Grace", applied.displayName());
    }

    @Test
    void older_or_replayed_events_are_ignored() {
        UUID eventId = UUID.randomUUID();
        EngagementActor actor = new EngagementActor(
            UUID.randomUUID(), "CANDIDATE", true, "Ada", null,
            Instant.parse("2026-07-18T09:00:00Z"), eventId);

        assertSame(actor, actor.apply(
            "RECRUITER", false, "Older", null, Instant.parse("2026-07-18T08:00:00Z"), UUID.randomUUID()));
        assertSame(actor, actor.apply(
            "RECRUITER", false, "Replay", null, Instant.parse("2026-07-18T10:00:00Z"), eventId));
        assertEquals("CANDIDATE", actor.role());
        assertTrue(actor.active());
    }
}
