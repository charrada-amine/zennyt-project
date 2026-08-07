package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.GetCandidateResumeUseCase;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GetCandidateResumeUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();
    private static final UUID POSITION_ID = UUID.randomUUID();
    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID INTRUS = UUID.randomUUID();

    private JobOfferRepository jobOffers;
    private TestResultRepository testResults;
    private SoftSkillsProjectionRepository softSkillsProjections;
    private SoftSkillsSummaryRepository softSkillsSummaries;
    private HardSkillsSummaryRepository hardSkillsSummaries;
    private GetCandidateResumeUseCase useCase;

    @BeforeEach
    void setUp() {
        jobOffers = mock(JobOfferRepository.class);
        testResults = mock(TestResultRepository.class);
        softSkillsProjections = mock(SoftSkillsProjectionRepository.class);
        softSkillsSummaries = mock(SoftSkillsSummaryRepository.class);
        hardSkillsSummaries = mock(HardSkillsSummaryRepository.class);
        useCase = new GetCandidateResumeUseCase(jobOffers, testResults, softSkillsProjections,
            softSkillsSummaries, hardSkillsSummaries);

        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(RECRUITER);
        when(offer.jobPositionId()).thenReturn(POSITION_ID);
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of());
        when(softSkillsProjections.findByCandidateId(CANDIDATE)).thenReturn(List.of());
        when(softSkillsSummaries.findByCandidateIdAndAudience(any(), any())).thenReturn(Optional.empty());
        when(hardSkillsSummaries.findByCandidateIdAndJobPositionIdAndAudience(any(), any(), any()))
            .thenReturn(Optional.empty());
    }

    private HardSkillHistoryEntry entry(UUID offerId) {
        return new HardSkillHistoryEntry(CANDIDATE, POSITION_ID, offerId, 72, true, Instant.now(), "SENIOR");
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
        assertThat(result.softSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.SOFT_SKILLS_NOT_PLAYED_EN);
    }

    /**
     * Un candidat qui a joué mais dont le résumé n'est pas encore écrit ne doit pas être
     * annoncé comme n'ayant jamais joué : ses scores par module alimentent déjà le Fit
     * Score affiché juste à côté, et les deux se contrediraient.
     */
    @Test
    void playedButNotYetSummarisedYieldsPendingRatherThanNeverPlayed() {
        when(softSkillsProjections.findByCandidateId(CANDIDATE)).thenReturn(List.of(
            SoftSkillsProjection.create(CANDIDATE, "MOVE_FAST", 85, 100, Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.softSkills().available()).isFalse();
        assertThat(result.softSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.SOFT_SKILLS_PENDING_EN)
            .isNotEqualTo(GetCandidateResumeUseCase.SOFT_SKILLS_NOT_PLAYED_EN);
    }

    @Test
    void softSkillsSummaryReturnedWhenAvailable() {
        when(softSkillsSummaries.findByCandidateIdAndAudience(CANDIDATE, ResumeAudience.RECRUITER))
            .thenReturn(Optional.of(new SoftSkillsSummary(CANDIDATE, ResumeAudience.RECRUITER,
                "fr", "en", Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.softSkills().available()).isTrue();
        assertThat(result.softSkills().textFr()).isEqualTo("fr");
    }

    /** P3 — le message doit dire que le Fit Score affiché est soft seul, pas seulement qu'un test manque. */
    @Test
    void noAttemptYieldsNotTestedFallbackExplainingTheSoftOnlyScore() {
        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);
        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_NOT_TESTED_EN)
            .contains("soft skills");
    }

    @Test
    void attemptWithoutSummaryYetYieldsPendingFallback() {
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of(entry(OFFER_ID)));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PENDING_EN);
    }

    @Test
    void hardSkillsSummaryReturnedWhenAvailable() {
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID)).thenReturn(List.of(entry(OFFER_ID)));
        when(hardSkillsSummaries.findByCandidateIdAndJobPositionIdAndAudience(
                CANDIDATE, POSITION_ID, ResumeAudience.RECRUITER))
            .thenReturn(Optional.of(HardSkillsSummary.create(CANDIDATE, POSITION_ID,
                ResumeAudience.RECRUITER, "fr hard", "en hard", Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isTrue();
        assertThat(result.hardSkills().textFr()).isEqualTo("fr hard");
    }

    /**
     * D1 — un test passé pour une <b>autre</b> offre du même métier suffit désormais à
     * fournir la section hard skills. C'est la proposition centrale du document.
     */
    @Test
    void testTakenForAnotherOfferOfTheSameJobPositionCountsAsTested() {
        when(testResults.findHardSkillHistory(CANDIDATE, POSITION_ID))
            .thenReturn(List.of(entry(UUID.randomUUID())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PENDING_EN);
    }

    @Test
    void selfReadReturnsTheCandidateAudience() {
        when(softSkillsSummaries.findByCandidateIdAndAudience(CANDIDATE, ResumeAudience.CANDIDATE))
            .thenReturn(Optional.of(new SoftSkillsSummary(CANDIDATE, ResumeAudience.CANDIDATE,
                "fr candidat", "en candidat", Instant.now())));

        var result = useCase.executeForSelf(CANDIDATE, OFFER_ID);

        assertThat(result.softSkills().textFr()).isEqualTo("fr candidat");
        verify(softSkillsSummaries, never())
            .findByCandidateIdAndAudience(CANDIDATE, ResumeAudience.RECRUITER);
    }

    /** La lecture candidat ne passe par aucun contrôle de propriété d'offre. */
    @Test
    void selfReadIgnoresOfferOwnership() {
        var result = useCase.executeForSelf(CANDIDATE, OFFER_ID);
        assertThat(result.hardSkills().textFr())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_NOT_TESTED_SELF_FR);
    }

    /** Sans offre, la section hard skills n'a pas de métier à viser — seul le soft répond. */
    @Test
    void selfReadWithoutOfferStillReturnsSoftSkills() {
        var result = useCase.executeForSelf(CANDIDATE, null);

        assertThat(result.softSkills().textFr())
            .isEqualTo(GetCandidateResumeUseCase.SOFT_SKILLS_NOT_PLAYED_SELF_FR);
        assertThat(result.hardSkills().available()).isFalse();
        verify(jobOffers, never()).findById(any());
    }
}
