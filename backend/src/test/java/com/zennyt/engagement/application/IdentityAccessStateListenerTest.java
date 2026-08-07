package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import org.junit.jupiter.api.Test;
import org.springframework.context.event.EventListener;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

class IdentityAccessStateListenerTest {
    private final EngagementActorRepository actors = mock(EngagementActorRepository.class);
    private final EngagementIdentityAccessStateProjector projector =
        new EngagementIdentityAccessStateProjector(actors);
    private final EngagementIdentityAccessStateListener listener =
        new EngagementIdentityAccessStateListener(projector);

    @Test
    void creates_projection_and_ignores_older_or_replayed_events() {
        UUID userId = UUID.randomUUID();
        Instant occurredAt = Instant.parse("2026-07-18T08:00:00Z");
        UUID eventId = UUID.randomUUID();
        var event = new UserAccessStateChangedEvent(
            eventId, occurredAt, userId, "CANDIDATE", true, "Ada Lovelace", "https://img.test/ada",
            null, null, null, null, null, null, null, null, null, null);
        when(actors.findById(userId)).thenReturn(Optional.empty());

        projector.project(event);

        verify(actors).save(argThat(actor -> actor.userId().equals(userId) && actor.active()));

        reset(actors);
        EngagementActor current = new EngagementActor(
            userId, "CANDIDATE", true, "Ada Lovelace", "https://img.test/ada", occurredAt, eventId);
        when(actors.findById(userId)).thenReturn(Optional.of(current));
        projector.project(new UserAccessStateChangedEvent(
            UUID.randomUUID(), occurredAt.minusSeconds(1), userId, "RECRUITER", false, "Older", null,
            null, null, null, null, null, null, null, null, null, null));
        projector.project(new UserAccessStateChangedEvent(
            eventId, occurredAt.plusSeconds(1), userId, "RECRUITER", false, "Replay", null,
            null, null, null, null, null, null, null, null, null, null));

        verify(actors, never()).save(any());
    }

    @Test
    void projection_runs_after_commit_in_its_own_transaction_not_joining_identity() throws Exception {
        Method on = EngagementIdentityAccessStateListener.class
            .getMethod("on", UserAccessStateChangedEvent.class);

        assertThat(on.isAnnotationPresent(EventListener.class))
            .as("le listener ne doit plus rejoindre la transaction émettrice via @EventListener")
            .isFalse();

        TransactionalEventListener txListener = on.getAnnotation(TransactionalEventListener.class);
        assertThat(txListener).isNotNull();
        assertThat(txListener.phase()).isEqualTo(TransactionPhase.AFTER_COMMIT);
        assertThat(txListener.fallbackExecution())
            .as("fallbackExecution conserve le rejeu du snapshot hors transaction")
            .isTrue();

        assertThat(on.getAnnotation(Transactional.class)).isNull();

        Method project = EngagementIdentityAccessStateProjector.class
            .getMethod("project", UserAccessStateChangedEvent.class);
        Transactional tx = project.getAnnotation(Transactional.class);
        assertThat(tx).isNotNull();
        assertThat(tx.propagation()).isEqualTo(Propagation.REQUIRES_NEW);
    }

    @Test
    void projection_failure_does_not_escape_after_commit_callback() {
        EngagementIdentityAccessStateProjector failing = mock(EngagementIdentityAccessStateProjector.class);
        doThrow(new IllegalStateException("projection down")).when(failing).project(any());
        var safeListener = new EngagementIdentityAccessStateListener(failing);

        safeListener.on(UserAccessStateChangedEvent.of(
            UUID.randomUUID(), "CANDIDATE", true, "Ada", null, null, null, null, null,
            null, null, null, null, null, null));

        verify(failing).project(any());
    }
}
