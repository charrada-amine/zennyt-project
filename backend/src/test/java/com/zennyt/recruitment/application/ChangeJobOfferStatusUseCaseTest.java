package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.ChangeJobOfferStatusUseCase;
import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garde-fou contre une régression subtile déjà survenue : l'événement était publié
 * depuis l'agrégat <b>retourné par le repository</b>, or l'adaptateur de persistance
 * reconstruit un objet neuf (rehydrate) qui ne porte aucun événement enregistré.
 * Résultat : {@link JobOfferStatusChangedEvent} n'était jamais publié sur un
 * changement de statut, donc ni le précalcul des Fit Score à la publication, ni la
 * purge à la fermeture ne se déclenchaient — sans la moindre erreur visible.
 */
class ChangeJobOfferStatusUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();

    private JobOfferRepository repository;
    private ApplicationEventPublisher events;
    private ChangeJobOfferStatusUseCase useCase;

    @BeforeEach
    void setUp() {
        repository = mock(JobOfferRepository.class);
        events = mock(ApplicationEventPublisher.class);
        // Reproduit fidèlement l'adaptateur réel : renvoie un agrégat reconstruit,
        // distinct de celui passé en argument et sans événements.
        when(repository.save(any())).thenAnswer(invocation -> {
            JobOffer in = invocation.getArgument(0);
            return rehydrated(in.id(), in.status());
        });
        useCase = new ChangeJobOfferStatusUseCase(repository, events);
    }

    @Test
    void publieLEvenementDeChangementDeStatut() {
        UUID offerId = UUID.randomUUID();
        when(repository.findById(offerId)).thenReturn(Optional.of(rehydrated(offerId, JobOfferStatus.ACTIVE)));

        useCase.execute(offerId, RECRUITER, JobOfferStatus.CLOSED);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(events).publishEvent(captor.capture());
        assertThat(captor.getValue()).isInstanceOf(JobOfferStatusChangedEvent.class);
        JobOfferStatusChangedEvent event = (JobOfferStatusChangedEvent) captor.getValue();
        assertThat(event.jobOfferId()).isEqualTo(offerId);
        assertThat(event.previousStatus()).isEqualTo(JobOfferStatus.ACTIVE);
        assertThat(event.newStatus()).isEqualTo(JobOfferStatus.CLOSED);
    }

    private static JobOffer rehydrated(UUID id, JobOfferStatus status) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(id, RECRUITER, null, "Développeur",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, UUID.randomUUID(), false, status, now, now);
    }
}
