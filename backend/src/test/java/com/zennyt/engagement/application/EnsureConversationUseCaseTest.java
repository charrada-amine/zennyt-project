package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.EnsureConversationUseCase;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class EnsureConversationUseCaseTest {

    private static final UUID APPLICATION = UUID.randomUUID();
    private static final UUID JOB = UUID.randomUUID();
    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID RECRUITER = UUID.randomUUID();

    private ConversationRepository conversations;
    private EngagementApplicationRepository applications;
    private EnsureConversationUseCase useCase;

    @BeforeEach
    void setUp() {
        conversations = mock(ConversationRepository.class);
        applications = mock(EngagementApplicationRepository.class);
        useCase = new EnsureConversationUseCase(conversations, applications);
    }

    private EngagementApplication projection() {
        return new EngagementApplication(APPLICATION, JOB, CANDIDATE, RECRUITER,
            "Backend Engineer", UUID.randomUUID(), Instant.now());
    }

    private Conversation conversation() {
        return Conversation.create(APPLICATION, JOB, CANDIDATE, RECRUITER, "Backend Engineer");
    }

    @Test
    void returns_existing_without_creating() {
        Conversation existing = conversation();
        when(conversations.findByApplicationIdAndParticipantId(APPLICATION, RECRUITER))
            .thenReturn(Optional.of(existing));

        EnsureConversationUseCase.Result result = useCase.execute(RECRUITER, APPLICATION);

        assertThat(result.created()).isFalse();
        assertThat(result.conversation()).isSameAs(existing);
        verify(conversations, never()).createIfAbsent(any());
    }

    @Test
    void creates_when_absent_for_a_participant() {
        Conversation persisted = conversation();
        when(conversations.findByApplicationIdAndParticipantId(APPLICATION, CANDIDATE))
            .thenReturn(Optional.empty(), Optional.of(persisted));
        when(applications.findById(APPLICATION)).thenReturn(Optional.of(projection()));
        when(conversations.createIfAbsent(any())).thenReturn(true);

        EnsureConversationUseCase.Result result = useCase.execute(CANDIDATE, APPLICATION);

        assertThat(result.created()).isTrue();
        assertThat(result.conversation().applicationId()).isEqualTo(APPLICATION);
        verify(conversations).createIfAbsent(any());
    }

    @Test
    void outsider_gets_404() {
        UUID outsider = UUID.randomUUID();
        when(conversations.findByApplicationIdAndParticipantId(APPLICATION, outsider))
            .thenReturn(Optional.empty());
        when(applications.findById(APPLICATION)).thenReturn(Optional.of(projection()));

        assertThatThrownBy(() -> useCase.execute(outsider, APPLICATION))
            .isInstanceOf(NotFoundException.class);
        verify(conversations, never()).createIfAbsent(any());
    }

    @Test
    void unknown_application_gets_404() {
        when(conversations.findByApplicationIdAndParticipantId(APPLICATION, CANDIDATE))
            .thenReturn(Optional.empty());
        when(applications.findById(APPLICATION)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(CANDIDATE, APPLICATION))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void concurrent_creation_falls_back_to_the_winner_as_not_created() {
        Conversation winner = conversation();
        when(conversations.findByApplicationIdAndParticipantId(APPLICATION, CANDIDATE))
            .thenReturn(Optional.empty())      // 1er check : rien
            .thenReturn(Optional.of(winner));  // après collision : la gagnante
        when(applications.findById(APPLICATION)).thenReturn(Optional.of(projection()));
        when(conversations.createIfAbsent(any())).thenReturn(false);

        EnsureConversationUseCase.Result result = useCase.execute(CANDIDATE, APPLICATION);

        assertThat(result.created()).isFalse();
        assertThat(result.conversation()).isSameAs(winner);
    }
}
