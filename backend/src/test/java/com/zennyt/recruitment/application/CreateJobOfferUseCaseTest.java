package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.CreateJobOfferUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Le métier ({@code jobPositionId}) est obligatoire depuis la suppression du repli IA
 * du Fit Score : sans lui, la formule n'a pas de pondération et l'offre resterait
 * définitivement sans score, donc reléguée en fin de fil candidat. Mieux vaut refuser
 * la création que publier une offre silencieusement invisible.
 */
class CreateJobOfferUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID POSITION = UUID.randomUUID();

    private JobOfferRepository offers;
    private JobPositionRepository positions;
    private CreateJobOfferUseCase useCase;

    @BeforeEach
    void setUp() {
        offers = mock(JobOfferRepository.class);
        positions = mock(JobPositionRepository.class);
        AssessmentRepository assessments = mock(AssessmentRepository.class);
        ApplicationEventPublisher events = mock(ApplicationEventPublisher.class);
        when(offers.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(positions.findById(POSITION)).thenReturn(Optional.of(
            JobPosition.rehydrate(POSITION, "Développeur", "IT, AI & Fintech",
                JobProfileType.TECHNIQUE, false, JobPositionStatus.APPROVED, null,
                null, null, null, null, Instant.now(), null, null)));
        useCase = new CreateJobOfferUseCase(offers, assessments, positions, events);
    }

    private CreateJobOfferUseCase.Command command(UUID jobPositionId) {
        return new CreateJobOfferUseCase.Command("Développeur", new Location("Tunis", "TN"),
            40000.0, 70000.0, ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.MID,
            "desc", "resp", "min", "pref", "offer", "apply", null, jobPositionId, false);
    }

    @Test
    void creeLOffreQuandLeMetierEstFourni() {
        JobOffer created = useCase.execute(RECRUITER, command(POSITION));

        assertThat(created.jobPositionId()).isEqualTo(POSITION);
        assertThat(created.status()).isEqualTo(JobOfferStatus.ACTIVE);
    }

    @Test
    void refuseUneOffreSansMetier() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER, command(null)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("jobPositionId");
        verify(offers, never()).save(any());
    }

    @Test
    void refuseUnMetierInexistant() {
        UUID inconnu = UUID.randomUUID();
        when(positions.findById(inconnu)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(RECRUITER, command(inconnu)))
            .isInstanceOf(NotFoundException.class);
        verify(offers, never()).save(any());
    }
}
