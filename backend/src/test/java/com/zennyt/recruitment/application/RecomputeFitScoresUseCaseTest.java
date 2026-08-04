package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class RecomputeFitScoresUseCaseTest {
    @Test
    void upsertsWithExistingIdAndSubscores() {
        UUID candidateId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        UUID existingId = UUID.randomUUID();
        FitScoreCalculatorPort calculator = inputs ->
            new FitScoreCalculatorPort.FitScoreResult(84, 77);
        FitScoreRepository scores = mock(FitScoreRepository.class);
        JobOfferRepository offers = mock(JobOfferRepository.class);
        SoftSkillsProjectionRepository soft = mock(SoftSkillsProjectionRepository.class);
        UUID recruiterId = UUID.randomUUID();
        JobOffer offer = mock(JobOffer.class);
        when(offer.id()).thenReturn(offerId);
        when(offer.recruiterId()).thenReturn(recruiterId);
        when(offer.description()).thenReturn("Java backend");
        RecruitmentActorRepository actors = mock(RecruitmentActorRepository.class);
        when(actors.findById(recruiterId)).thenReturn(Optional.of(
            new RecruitmentActor(recruiterId, "RECRUITER", true, null, null, null, null,
                "Zennyt Inc.", "Entreprise produit", null, null, null, null, null, null, null,
                Instant.now(), UUID.randomUUID())));
        when(soft.findByCandidateId(candidateId)).thenReturn(List.of(
            SoftSkillsProjection.create(candidateId, "MOVE_FAST", 77, Instant.now())));
        when(scores.findByCandidateIdAndJobOfferId(candidateId, offerId)).thenReturn(Optional.of(
            FitScore.calculated(existingId, candidateId, offerId, 10, 10, null, 100, Instant.now())));
        when(scores.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        JobRoleProfileResolver roleProfileResolver = mock(JobRoleProfileResolver.class);
        TestResultRepository testResults = mock(TestResultRepository.class);

        FitScore result = new RecomputeFitScoresUseCase(calculator, scores, offers, soft,
                roleProfileResolver, testResults)
            .recompute(candidateId, offer);

        assertThat(result.id()).isEqualTo(existingId);
        assertThat(result.score()).isEqualTo(84);
        assertThat(result.softSkillScore()).isEqualTo(77);
    }

    @Test
    void publicationBatchIsBounded() {
        FitScoreCalculatorPort calculator = inputs ->
            new FitScoreCalculatorPort.FitScoreResult(50, 50);
        FitScoreRepository scores = mock(FitScoreRepository.class);
        JobOfferRepository offers = mock(JobOfferRepository.class);
        SoftSkillsProjectionRepository soft = mock(SoftSkillsProjectionRepository.class);
        RecruitmentActorRepository actors = mock(RecruitmentActorRepository.class);
        UUID offerId = UUID.randomUUID();
        when(offers.findById(offerId)).thenReturn(Optional.of(mock(JobOffer.class)));
        when(soft.findCandidateIds(RecomputeFitScoresUseCase.MAX_BATCH_SIZE)).thenReturn(List.of());
        JobRoleProfileResolver roleProfileResolver = mock(JobRoleProfileResolver.class);
        TestResultRepository testResults = mock(TestResultRepository.class);

        var pairs = new RecomputeFitScoresUseCase(calculator, scores, offers, soft,
                roleProfileResolver, testResults)
            .pairsForOffer(offerId);

        verify(soft).findCandidateIds(RecomputeFitScoresUseCase.MAX_BATCH_SIZE);
        assertThat(pairs).isEmpty();
    }
}
