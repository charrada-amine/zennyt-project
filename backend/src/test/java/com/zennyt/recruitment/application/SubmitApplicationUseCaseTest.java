package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.command.SubmitApplicationCommand;
import com.zennyt.recruitment.application.usecase.SubmitApplicationUseCase;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garantit que la soumission d'une candidature publie réellement
 * {@link ApplicationSubmittedEvent}. Le mock de {@code save()} réhydre l'agrégat
 * (liste d'événements vide), comme le fait l'adaptateur JPA réel : c'est ce qui
 * démasque le bug historique de publication depuis le retour de {@code save()}.
 */
class SubmitApplicationUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID JOB_OFFER = UUID.randomUUID();

    private ApplicationRepository repository;
    private JobOfferRepository jobOffers;
    private ApplicationEventPublisher events;
    private SubmitApplicationUseCase useCase;

    @BeforeEach
    void setUp() {
        repository = mock(ApplicationRepository.class);
        jobOffers = mock(JobOfferRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitApplicationUseCase(repository, jobOffers, events);

        when(repository.existsByCandidateIdAndJobOfferId(CANDIDATE, JOB_OFFER)).thenReturn(false);
        JobOffer offer = mock(JobOffer.class);
        when(offer.status()).thenReturn(JobOfferStatus.ACTIVE);
        when(offer.recruiterId()).thenReturn(UUID.randomUUID());
        when(offer.title()).thenReturn("Backend Engineer");
        when(jobOffers.findById(JOB_OFFER)).thenReturn(Optional.of(offer));

        // Reproduit l'adaptateur réel : save() réhydrate → l'instance retournée
        // repart avec une liste d'événements vide.
        when(repository.save(any(Application.class))).thenAnswer(invocation -> {
            Application a = invocation.getArgument(0);
            return Application.rehydrate(a.id(), a.candidateId(), a.jobOfferId(),
                a.status(), a.appliedAt(), a.updatedAt());
        });
    }

    @Test
    void submit_publishes_ApplicationSubmittedEvent_with_correct_fields() {
        Application saved = useCase.execute(new SubmitApplicationCommand(CANDIDATE, JOB_OFFER));

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(events).publishEvent(captor.capture());

        assertThat(captor.getValue()).isInstanceOf(ApplicationSubmittedEvent.class);
        ApplicationSubmittedEvent event = (ApplicationSubmittedEvent) captor.getValue();
        assertThat(event.applicationId()).isEqualTo(saved.id());
        assertThat(event.candidateId()).isEqualTo(CANDIDATE);
        assertThat(event.jobOfferId()).isEqualTo(JOB_OFFER);
        assertThat(event.recruiterId()).isNotNull();
        assertThat(event.jobTitle()).isEqualTo("Backend Engineer");
    }

    @Test
    void duplicate_application_is_rejected_and_publishes_nothing() {
        when(repository.existsByCandidateIdAndJobOfferId(CANDIDATE, JOB_OFFER)).thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(new SubmitApplicationCommand(CANDIDATE, JOB_OFFER)))
            .isInstanceOf(ConflictException.class);

        verify(repository, never()).save(any());
        verify(events, never()).publishEvent(any());
    }
}
