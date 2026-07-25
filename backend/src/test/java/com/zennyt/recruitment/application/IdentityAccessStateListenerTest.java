package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
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
    private final RecruitmentActorRepository repository = mock(RecruitmentActorRepository.class);
    private final IdentityAccessStateProjector projector = new IdentityAccessStateProjector(repository);
    private final IdentityAccessStateListener listener = new IdentityAccessStateListener(projector);

    @Test
    void createsProjectionThenAppliesOnlyNewerEvents() {
        UUID userId = UUID.randomUUID();
        Instant firstAt = Instant.parse("2026-07-14T08:00:00Z");
        var first = new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt, userId,
            "CANDIDATE", true, "Aicha Gharbi", null, "Tunis", "Tunisie", null, null);
        when(repository.findById(userId)).thenReturn(Optional.empty());

        projector.project(first);

        verify(repository).save(argThat(actor -> actor.active()
            && "CANDIDATE".equals(actor.role()) && actor.publicUserId().equals(userId)));

        reset(repository);
        RecruitmentActor current = new RecruitmentActor(userId, "CANDIDATE", true,
            "Aicha Gharbi", null, "Tunis", "Tunisie", null, null, firstAt, first.eventId());
        when(repository.findById(userId)).thenReturn(Optional.of(current));
        var newer = new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt.plusSeconds(10), userId,
            "RECRUITER", false, "Aicha Gharbi", null, "Tunis", "Tunisie", null, null);

        projector.project(newer);

        verify(repository).save(argThat(actor -> !actor.active()
            && "RECRUITER".equals(actor.role())
            && actor.lastEventId().equals(newer.eventId())));

        reset(repository);
        when(repository.findById(userId)).thenReturn(Optional.of(current));
        projector.project(new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt.minusSeconds(1), userId,
            "RECRUITER", false, "Aicha Gharbi", null, "Tunis", "Tunisie", null, null));
        verify(repository, never()).save(any());
    }

    @Test
    void projection_runs_after_commit_in_its_own_transaction_not_joining_identity() throws Exception {
        Method on = IdentityAccessStateListener.class
            .getMethod("on", UserAccessStateChangedEvent.class);

        assertThat(on.isAnnotationPresent(EventListener.class))
            .as("le listener ne doit plus rejoindre la transaction émettrice via @EventListener")
            .isFalse();

        TransactionalEventListener txListener = on.getAnnotation(TransactionalEventListener.class);
        assertThat(txListener).isNotNull();
        assertThat(txListener.phase()).isEqualTo(TransactionPhase.AFTER_COMMIT);
        assertThat(txListener.fallbackExecution()).isTrue();

        assertThat(on.getAnnotation(Transactional.class)).isNull();

        Method project = IdentityAccessStateProjector.class
            .getMethod("project", UserAccessStateChangedEvent.class);
        Transactional tx = project.getAnnotation(Transactional.class);
        assertThat(tx).isNotNull();
        assertThat(tx.propagation()).isEqualTo(Propagation.REQUIRES_NEW);
    }

    @Test
    void projection_failure_does_not_escape_after_commit_callback() {
        IdentityAccessStateProjector failing = mock(IdentityAccessStateProjector.class);
        doThrow(new IllegalStateException("projection down")).when(failing).project(any());
        var safeListener = new IdentityAccessStateListener(failing);

        safeListener.on(UserAccessStateChangedEvent.of(
            UUID.randomUUID(), "CANDIDATE", true, "Ada", null, null, null, null, null));

        verify(failing).project(any());
    }
}
