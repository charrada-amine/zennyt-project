package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

class IdentityAccessStateListenerTest {
    private final RecruitmentActorRepository repository = mock(RecruitmentActorRepository.class);
    private final IdentityAccessStateListener listener = new IdentityAccessStateListener(repository);

    @Test
    void createsProjectionThenAppliesOnlyNewerEvents() {
        UUID userId = UUID.randomUUID();
        Instant firstAt = Instant.parse("2026-07-14T08:00:00Z");
        var first = new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt, userId,
            "CANDIDATE", true);
        when(repository.findById(userId)).thenReturn(Optional.empty());

        listener.on(first);

        verify(repository).save(argThat(actor -> actor.active()
            && "CANDIDATE".equals(actor.role()) && actor.publicUserId().equals(userId)));

        reset(repository);
        RecruitmentActor current = new RecruitmentActor(userId, "CANDIDATE", true,
            firstAt, first.eventId());
        when(repository.findById(userId)).thenReturn(Optional.of(current));
        var newer = new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt.plusSeconds(10), userId,
            "RECRUITER", false);

        listener.on(newer);

        verify(repository).save(argThat(actor -> !actor.active()
            && "RECRUITER".equals(actor.role())
            && actor.lastEventId().equals(newer.eventId())));

        reset(repository);
        when(repository.findById(userId)).thenReturn(Optional.of(current));
        listener.on(new UserAccessStateChangedEvent(UUID.randomUUID(), firstAt.minusSeconds(1), userId,
            "RECRUITER", false));
        verify(repository, never()).save(any());
    }
}
