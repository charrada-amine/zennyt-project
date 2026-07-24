package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.application.usecase.GenerateHardSkillsSummaryUseCase;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GenerateHardSkillsSummaryUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID RESULT_ID = UUID.randomUUID();

    private TestResultRepository testResults;
    private JobOfferRepository jobOffers;
    private CvProfileProjectionRepository cvProfiles;
    private ResumeSummaryGeneratorPort generator;
    private HardSkillsSummaryRepository summaries;
    private GenerateHardSkillsSummaryUseCase useCase;

    @BeforeEach
    void setUp() {
        testResults = mock(TestResultRepository.class);
        jobOffers = mock(JobOfferRepository.class);
        cvProfiles = mock(CvProfileProjectionRepository.class);
        generator = mock(ResumeSummaryGeneratorPort.class);
        summaries = mock(HardSkillsSummaryRepository.class);
        useCase = new GenerateHardSkillsSummaryUseCase(testResults, jobOffers, cvProfiles, generator, summaries);
    }

    private TestResult result(int percentage, boolean passed) {
        Instant now = Instant.now();
        return TestResult.rehydrate(RESULT_ID, OFFER_ID, UUID.randomUUID(), CANDIDATE,
            percentage, percentage, passed, List.of(), now, now, 0, TestResultStatus.COMPLETED);
    }

    @Test
    void unknownResultIsANoOp() {
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.empty());

        useCase.execute(RESULT_ID);

        verify(generator, never()).generateHardSkillsSummary(any(), any(), anyInt(), anyBoolean());
        verify(summaries, never()).save(any());
    }

    @Test
    void generatesUsingCvAndResultThenInsertsNewSummary() {
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(72, true)));
        JobOffer offer = mock(JobOffer.class);
        when(offer.title()).thenReturn("Senior React Developer");
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(cvProfiles.findByCandidateId(CANDIDATE))
            .thenReturn(Optional.of(new CvProfileProjection(CANDIDATE, "Skills: React, Redux", Instant.now())));
        when(summaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.empty());
        when(generator.generateHardSkillsSummary("Senior React Developer", "Skills: React, Redux", 72, true))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("fr", "en"));

        useCase.execute(RESULT_ID);

        var captor = org.mockito.ArgumentCaptor.forClass(HardSkillsSummary.class);
        verify(summaries).save(captor.capture());
        assertThat(captor.getValue().candidateId()).isEqualTo(CANDIDATE);
        assertThat(captor.getValue().jobOfferId()).isEqualTo(OFFER_ID);
        assertThat(captor.getValue().textFr()).isEqualTo("fr");
    }

    @Test
    void reusesExistingSummaryIdOnRegeneration() {
        UUID existingId = UUID.randomUUID();
        when(testResults.findById(RESULT_ID)).thenReturn(Optional.of(result(90, true)));
        JobOffer offer = mock(JobOffer.class);
        when(offer.title()).thenReturn("Backend Engineer");
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(cvProfiles.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(summaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.of(
            new HardSkillsSummary(existingId, CANDIDATE, OFFER_ID, "old fr", "old en", Instant.now())));
        when(generator.generateHardSkillsSummary(any(), any(), anyInt(), anyBoolean()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("new fr", "new en"));

        useCase.execute(RESULT_ID);

        var captor = org.mockito.ArgumentCaptor.forClass(HardSkillsSummary.class);
        verify(summaries).save(captor.capture());
        assertThat(captor.getValue().id()).isEqualTo(existingId);
        assertThat(captor.getValue().textFr()).isEqualTo("new fr");
    }
}
