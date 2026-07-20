package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.GetCandidateResumeUseCase;
import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class GetCandidateResumeUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID INTRUS = UUID.randomUUID();

    private JobOfferRepository jobOffers;
    private AssessmentAttemptRepository attempts;
    private SoftSkillsSummaryRepository softSkillsSummaries;
    private HardSkillsSummaryRepository hardSkillsSummaries;
    private GetCandidateResumeUseCase useCase;

    @BeforeEach
    void setUp() {
        jobOffers = mock(JobOfferRepository.class);
        attempts = mock(AssessmentAttemptRepository.class);
        softSkillsSummaries = mock(SoftSkillsSummaryRepository.class);
        hardSkillsSummaries = mock(HardSkillsSummaryRepository.class);
        useCase = new GetCandidateResumeUseCase(jobOffers, attempts, softSkillsSummaries, hardSkillsSummaries);

        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(RECRUITER);
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(attempts.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(List.of());
        when(softSkillsSummaries.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(hardSkillsSummaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.empty());
    }

    @Test
    void unknownOfferRefused() {
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> useCase.execute(CANDIDATE, OFFER_ID, RECRUITER))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void offerFromAnotherRecruiterRefused() {
        assertThatThrownBy(() -> useCase.execute(CANDIDATE, OFFER_ID, INTRUS))
            .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void noGamesPlayedYieldsSoftSkillsFallback() {
        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);
        assertThat(result.softSkills().available()).isFalse();
    }

    @Test
    void softSkillsSummaryReturnedWhenAvailable() {
        when(softSkillsSummaries.findByCandidateId(CANDIDATE)).thenReturn(Optional.of(
            new SoftSkillsSummary(CANDIDATE, "fr", "en", Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.softSkills().available()).isTrue();
        assertThat(result.softSkills().textFr()).isEqualTo("fr");
    }

    @Test
    void noAttemptYieldsNotTestedFallback() {
        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);
        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_NOT_TESTED_EN);
    }

    @Test
    void attemptWithoutSummaryYetYieldsPendingFallback() {
        AssessmentAttempt attempt = AssessmentAttempt.rehydrate(UUID.randomUUID(), UUID.randomUUID(),
            CANDIDATE, OFFER_ID, UUID.randomUUID(), 80, true, true, IntegrityStatus.VALIDATED, Instant.now());
        when(attempts.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(List.of(attempt));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PENDING_EN);
    }

    @Test
    void hardSkillsSummaryReturnedWhenAvailable() {
        AssessmentAttempt attempt = AssessmentAttempt.rehydrate(UUID.randomUUID(), UUID.randomUUID(),
            CANDIDATE, OFFER_ID, UUID.randomUUID(), 80, true, true, IntegrityStatus.VALIDATED, Instant.now());
        when(attempts.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(List.of(attempt));
        when(hardSkillsSummaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.of(
            HardSkillsSummary.create(CANDIDATE, OFFER_ID, "fr hard", "en hard", Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isTrue();
        assertThat(result.hardSkills().textFr()).isEqualTo("fr hard");
    }
}
