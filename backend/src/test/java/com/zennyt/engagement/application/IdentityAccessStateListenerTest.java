package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

class IdentityAccessStateListenerTest {
    private final EngagementActorRepository actors = mock(EngagementActorRepository.class);
    private final EngagementIdentityAccessStateListener listener =
        new EngagementIdentityAccessStateListener(actors);

    @Test
    void creates_projection_and_ignores_older_or_replayed_events() {
        UUID userId = UUID.randomUUID();
        Instant occurredAt = Instant.parse("2026-07-18T08:00:00Z");
        UUID eventId = UUID.randomUUID();
        var event = new UserAccessStateChangedEvent(
            eventId, occurredAt, userId, "CANDIDATE", true, "Ada Lovelace", "https://img.test/ada");
        when(actors.findById(userId)).thenReturn(Optional.empty());

        listener.on(event);

        verify(actors).save(argThat(actor -> actor.userId().equals(userId) && actor.active()));

        reset(actors);
        EngagementActor current = new EngagementActor(
            userId, "CANDIDATE", true, "Ada Lovelace", "https://img.test/ada", occurredAt, eventId);
        when(actors.findById(userId)).thenReturn(Optional.of(current));
        listener.on(new UserAccessStateChangedEvent(
            UUID.randomUUID(), occurredAt.minusSeconds(1), userId, "RECRUITER", false, "Older", null));
        listener.on(new UserAccessStateChangedEvent(
            eventId, occurredAt.plusSeconds(1), userId, "RECRUITER", false, "Replay", null));

        verify(actors, never()).save(any());
    }
}
