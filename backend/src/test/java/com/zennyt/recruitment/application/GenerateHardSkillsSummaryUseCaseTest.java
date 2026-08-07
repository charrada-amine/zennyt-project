package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.application.usecase.GenerateHardSkillsSummaryUseCase;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.HardSkillTrend;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class GenerateHardSkillsSummaryUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID POSITION_ID = UUID.randomUUID();
    private static final UUID RESULT_ID = UUID.randomUUID();

    private TestResultRepository testResults;
    private JobOfferRepository jobOffers;
    private JobPositionRepository jobPositions;
    private CvProfileProjectionRepository cvProfiles;
    private ResumeSummaryGeneratorPort generator;
    private HardSkillsSummaryRepository summaries;
    private GenerateHardSkillsSummaryUseCase useCase;

    @BeforeEach
    void setUp() {
        testResults = mock(TestResultRepository.class);
        jobOffers = mock(JobOfferRepository.class);
        jobPositions = mock(JobPositionRepository.class);
        cvProfiles = mock(CvProfileProjectionRepository.class);
        generator = mock(ResumeSummaryGeneratorPort.class);
        summaries = mock(HardSkillsSummaryRepository.class);
        useCase = new GenerateHardSkillsSummaryUseCase(testResults, jobOffers, jobPositions,
            cvProfiles, generator, summaries);
    }

    private TestResult result(int percentage, boolean passed) {
        Instant now = Instant.now();
        return TestResult.rehydrate(RESULT_ID, OFFER_ID, UUID.randomUUID(), CANDIDATE,
            percentage, percentage, passed, List.of(), now, now, 0, TestResultStatus.COMPLETED);
    }

    private HardSkillHistoryEntry entry(UUID offerId, int percentage, Instant completedAt) {
        return new HardSkillHistoryEntry(CANDIDATE, POSITION_ID, offerId, percentage,
            percentage >= 70, completedAt, "SENIOR");
    }

    private JobOffer offreAvecMetier() {
        JobOffer offer = mock(JobOffer.class);
        when(offer.jobPositionId()).thenReturn(POSITION_ID);
        return offer;
    }

    @Test
    void unknownResultIsANoOp() {
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.empty());

        useCase.execute(RESULT_ID);

        verify(generator, never()).generateHardSkillsSummary(any(), any());
        verify(summaries, never()).save(any());
    }

    /** Une offre héritée sans métier n'a pas d'historique à résumer : rien n'est écrit. */
    @Test
    void offerWithoutJobPositionIsANoOp() {
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(72, true)));
        JobOffer offer = mock(JobOffer.class);
        when(offer.jobPositionId()).thenReturn(null);
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));

        useCase.execute(RESULT_ID);

        verify(generator, never()).generateHardSkillsSummary(any(), any());
        verify(summaries, never()).save(any());
    }

    @Test
    void generatesBothAudiencesFromTheJobPositionHistory() {
        Instant now = Instant.now();
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(72, true)));
        JobOffer offer = offreAvecMetier();
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(jobPositions.findById(POSITION_ID)).thenReturn(Optional.of(
            JobPosition.propose("Développeur", "IT", UUID.randomUUID(), null, null)));
        when(cvProfiles.findByCandidateId(CANDIDATE))
            .thenReturn(Optional.of(new CvProfileProjection(CANDIDATE, "Skills: React, Redux", now)));
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of(
            entry(OFFER_ID, 72, now),
            entry(UUID.randomUUID(), 55, now.minus(200, ChronoUnit.DAYS))));
        when(summaries.findByCandidateIdAndJobPositionIdAndAudience(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(generator.generateHardSkillsSummary(any(), any()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("fr", "en"));

        useCase.execute(RESULT_ID);

        // Deux publics, donc deux générations et deux lignes — P5.
        var contextCaptor = org.mockito.ArgumentCaptor.forClass(
            ResumeSummaryGeneratorPort.HardSkillsContext.class);
        verify(generator, times(2)).generateHardSkillsSummary(contextCaptor.capture(), any());
        assertThat(contextCaptor.getAllValues()).allSatisfy(ctx -> {
            assertThat(ctx.jobPositionName()).isEqualTo("Développeur");
            assertThat(ctx.cvText()).isEqualTo("Skills: React, Redux");
        });
        verify(generator).generateHardSkillsSummary(any(), eq(ResumeAudience.RECRUITER));
        verify(generator).generateHardSkillsSummary(any(), eq(ResumeAudience.CANDIDATE));

        var captor = org.mockito.ArgumentCaptor.forClass(HardSkillsSummary.class);
        verify(summaries, times(2)).save(captor.capture());
        assertThat(captor.getAllValues()).allSatisfy(summary -> {
            assertThat(summary.candidateId()).isEqualTo(CANDIDATE);
            assertThat(summary.jobPositionId()).isEqualTo(POSITION_ID);
            assertThat(summary.textFr()).isEqualTo("fr");
        });
        assertThat(captor.getAllValues()).extracting(HardSkillsSummary::audience)
            .containsExactlyInAnyOrder(ResumeAudience.RECRUITER, ResumeAudience.CANDIDATE);
    }

    /**
     * L'historique transmis au générateur contient bien <b>tous</b> les tests du métier, y
     * compris ceux passés pour d'autres offres — c'est tout l'objet de D1.
     */
    @Test
    void passesTheWholeJobPositionHistoryToTheGenerator() {
        Instant now = Instant.now();
        UUID autreOffre = UUID.randomUUID();
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(80, true)));
        JobOffer offer = offreAvecMetier();
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(jobPositions.findById(POSITION_ID)).thenReturn(Optional.empty());
        when(cvProfiles.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of(
            entry(OFFER_ID, 80, now),
            entry(autreOffre, 65, now.minus(180, ChronoUnit.DAYS)),
            entry(autreOffre, 40, now.minus(365, ChronoUnit.DAYS))));
        when(summaries.findByCandidateIdAndJobPositionIdAndAudience(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(generator.generateHardSkillsSummary(any(), any()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("fr", "en"));

        useCase.execute(RESULT_ID);

        var captor = org.mockito.ArgumentCaptor.forClass(
            ResumeSummaryGeneratorPort.HardSkillsContext.class);
        verify(generator, atLeastOnce()).generateHardSkillsSummary(captor.capture(), any());
        assertThat(captor.getValue().history()).hasSize(3);
    }

    /**
     * Le cas réel qui a révélé le défaut : 100 % puis 50 %, les deux le même jour. Le
     * générateur doit recevoir DECLINING, pas avoir à le déduire — c'est cette déduction
     * que le modèle avait ratée, annonçant « une amélioration significative ».
     */
    @Test
    void transmetLaTrajectoireCalculeeAuGenerateur() {
        Instant now = Instant.now();
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(50, false)));
        JobOffer offer = offreAvecMetier();
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(jobPositions.findById(POSITION_ID)).thenReturn(Optional.empty());
        when(cvProfiles.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of(
            entry(OFFER_ID, 50, now),
            entry(UUID.randomUUID(), 100, now.minus(6, ChronoUnit.HOURS))));
        when(summaries.findByCandidateIdAndJobPositionIdAndAudience(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(generator.generateHardSkillsSummary(any(), any()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("fr", "en"));

        useCase.execute(RESULT_ID);

        var captor = org.mockito.ArgumentCaptor.forClass(
            ResumeSummaryGeneratorPort.HardSkillsContext.class);
        verify(generator, atLeastOnce()).generateHardSkillsSummary(captor.capture(), any());
        assertThat(captor.getValue().trend()).isEqualTo(HardSkillTrend.DECLINING);
        // L'ordre transmis reste celui de la lecture : le plus récent en tête.
        assertThat(captor.getValue().history().get(0).percentage()).isEqualTo(50);
    }

    @Test
    void reusesExistingSummaryIdOnRegeneration() {
        UUID existingId = UUID.randomUUID();
        Instant now = Instant.now();
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(90, true)));
        JobOffer offer = offreAvecMetier();
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(jobPositions.findById(POSITION_ID)).thenReturn(Optional.empty());
        when(cvProfiles.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID))
            .thenReturn(List.of(entry(OFFER_ID, 90, now)));
        when(summaries.findByCandidateIdAndJobPositionIdAndAudience(
                CANDIDATE, POSITION_ID, ResumeAudience.RECRUITER))
            .thenReturn(Optional.of(new HardSkillsSummary(existingId, CANDIDATE, POSITION_ID,
                ResumeAudience.RECRUITER, "old fr", "old en", now)));
        when(summaries.findByCandidateIdAndJobPositionIdAndAudience(
                CANDIDATE, POSITION_ID, ResumeAudience.CANDIDATE))
            .thenReturn(Optional.empty());
        when(generator.generateHardSkillsSummary(any(), any()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("new fr", "new en"));

        useCase.execute(RESULT_ID);

        var captor = org.mockito.ArgumentCaptor.forClass(HardSkillsSummary.class);
        verify(summaries, times(2)).save(captor.capture());
        var recruteur = captor.getAllValues().stream()
            .filter(summary -> summary.audience() == ResumeAudience.RECRUITER).findFirst().orElseThrow();
        assertThat(recruteur.id()).isEqualTo(existingId);
        assertThat(recruteur.textFr()).isEqualTo("new fr");
    }
}
