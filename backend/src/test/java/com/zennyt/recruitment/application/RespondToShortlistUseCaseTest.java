package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RespondToShortlistUseCase;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
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

/** Garde-fous du 20/07 : le candidat répond seul à sa présélection. */
class RespondToShortlistUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID INTRUS = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID APPLICATION_ID = UUID.randomUUID();

    private ApplicationRepository repository;
    private RespondToShortlistUseCase useCase;

    @BeforeEach
    void setUp() {
        repository = mock(ApplicationRepository.class);
        useCase = new RespondToShortlistUseCase(repository);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    private Application shortlistedApplication() {
        return Application.rehydrate(APPLICATION_ID, CANDIDATE, OFFER_ID,
            ApplicationStatus.SHORTLISTED, Instant.now(), Instant.now());
    }

    private Application pendingApplication() {
        return Application.rehydrate(APPLICATION_ID, CANDIDATE, OFFER_ID,
            ApplicationStatus.PENDING, Instant.now(), Instant.now());
    }

    @Test
    void candidateApprovesShortlistedApplication() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(shortlistedApplication()));

        Application result = useCase.execute(APPLICATION_ID, CANDIDATE, true);

        assertThat(result.status()).isEqualTo(ApplicationStatus.APPROVED);
    }

    @Test
    void candidateRejectsShortlistedApplication() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(shortlistedApplication()));

        Application result = useCase.execute(APPLICATION_ID, CANDIDATE, false);

        assertThat(result.status()).isEqualTo(ApplicationStatus.REJECTED);
    }

    @Test
    void anotherCandidateCannotRespond() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(shortlistedApplication()));

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, INTRUS, true))
            .isInstanceOf(ForbiddenException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void cannotRespondBeforeShortlisted() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(pendingApplication()));

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, CANDIDATE, true))
            .isInstanceOf(IllegalStateException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void unknownApplicationRefused() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, CANDIDATE, true))
            .isInstanceOf(NotFoundException.class);
    }
}
