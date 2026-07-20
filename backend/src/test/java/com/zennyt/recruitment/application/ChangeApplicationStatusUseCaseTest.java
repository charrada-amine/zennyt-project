package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.ChangeApplicationStatusUseCase;
import com.zennyt.recruitment.domain.event.ApplicationShortlistedEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garde-fous du 20/07 : le recruteur ne pilote que la présélection
 * (PENDING -> SHORTLISTED / REJECTED) ; APPROVED et le rejet post-SHORTLISTED
 * appartiennent désormais au candidat via RespondToShortlistUseCase.
 */
class ChangeApplicationStatusUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID INTRUS = UUID.randomUUID();
    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID APPLICATION_ID = UUID.randomUUID();

    private ApplicationRepository repository;
    private JobOfferRepository jobOffers;
    private ApplicationEventPublisher events;
    private ChangeApplicationStatusUseCase useCase;

    @BeforeEach
    void setUp() {
        repository = mock(ApplicationRepository.class);
        jobOffers = mock(JobOfferRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new ChangeApplicationStatusUseCase(repository, jobOffers, events);

        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(RECRUITER);
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    private Application pendingApplication() {
        return Application.rehydrate(APPLICATION_ID, CANDIDATE, OFFER_ID,
            ApplicationStatus.PENDING, java.time.Instant.now(), java.time.Instant.now());
    }

    private Application shortlistedApplication() {
        return Application.rehydrate(APPLICATION_ID, CANDIDATE, OFFER_ID,
            ApplicationStatus.SHORTLISTED, java.time.Instant.now(), java.time.Instant.now());
    }

    @Test
    void recruiterCanShortlistAndEventIsPublished() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(pendingApplication()));

        Application result = useCase.execute(APPLICATION_ID, RECRUITER, ApplicationStatus.SHORTLISTED);

        assertThat(result.status()).isEqualTo(ApplicationStatus.SHORTLISTED);
        verify(events).publishEvent(any(ApplicationShortlistedEvent.class));
    }

    @Test
    void recruiterCanRejectFromPending() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(pendingApplication()));

        Application result = useCase.execute(APPLICATION_ID, RECRUITER, ApplicationStatus.REJECTED);

        assertThat(result.status()).isEqualTo(ApplicationStatus.REJECTED);
    }

    @Test
    void recruiterCannotApproveDirectly() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(shortlistedApplication()));

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, RECRUITER, ApplicationStatus.APPROVED))
            .isInstanceOf(ForbiddenException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void recruiterCannotRejectAfterShortlisting() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(shortlistedApplication()));

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, RECRUITER, ApplicationStatus.REJECTED))
            .isInstanceOf(ForbiddenException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void applicationFromAnotherOfferRefused() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.of(pendingApplication()));

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, INTRUS, ApplicationStatus.SHORTLISTED))
            .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void unknownApplicationRefused() {
        when(repository.findById(APPLICATION_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(APPLICATION_ID, RECRUITER, ApplicationStatus.SHORTLISTED))
            .isInstanceOf(NotFoundException.class);
    }
}
