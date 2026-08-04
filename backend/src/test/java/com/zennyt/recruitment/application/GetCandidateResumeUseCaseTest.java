package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.GetCandidateResumeUseCase;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
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
    private TestResultRepository testResults;
    private SoftSkillsSummaryRepository softSkillsSummaries;
    private HardSkillsSummaryRepository hardSkillsSummaries;
    private JobRoleProfileResolver roleProfileResolver;
    private JobOffer offer;
    private GetCandidateResumeUseCase useCase;

    @BeforeEach
    void setUp() {
        jobOffers = mock(JobOfferRepository.class);
        testResults = mock(TestResultRepository.class);
        softSkillsSummaries = mock(SoftSkillsSummaryRepository.class);
        hardSkillsSummaries = mock(HardSkillsSummaryRepository.class);
        roleProfileResolver = mock(JobRoleProfileResolver.class);
        useCase = new GetCandidateResumeUseCase(jobOffers, testResults, softSkillsSummaries,
            hardSkillsSummaries, roleProfileResolver);

        offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(RECRUITER);
        when(jobOffers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(testResults.existsByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(false);
        when(softSkillsSummaries.findByCandidateId(CANDIDATE)).thenReturn(Optional.empty());
        when(hardSkillsSummaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.empty());
        // roleProfileResolver.resolve(offer) defaults to null (unstubbed mock) — same as
        // today's "no role profile resolved" case, preserving the existing fallbacks below.
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
        when(testResults.existsByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(true);

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PENDING_EN);
    }

    /**
     * F18 (FITSCORE_REMEDIATION.md §3 index F18, décision D-F) — pour un métier
     * ARTISTIQUE évalué uniquement par Portfolio, le recruteur ne doit jamais
     * voir "un test doit être passé" (faux — aucun QCM n'est prévu pour ce
     * profil) : le message explicite l'emporte sur les replis "not tested"/
     * "pending", même si aucun test n'a jamais été tenté.
     */
    @Test
    void artistiquePortfolioOnlyProfileYieldsExplicitDisclaimerInsteadOfNotTested() {
        JobRoleProfile portfolioProfile = new JobRoleProfile(JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR,
            45, 55, 55, 40, 15, 15, 15, 15, TypeEvaluationHard.PORTFOLIO, false, Instant.now());
        when(roleProfileResolver.resolve(offer)).thenReturn(portfolioProfile);

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isFalse();
        assertThat(result.hardSkills().textFr())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PORTFOLIO_ONLY_FR);
        assertThat(result.hardSkills().textEn())
            .isEqualTo(GetCandidateResumeUseCase.HARD_SKILLS_PORTFOLIO_ONLY_EN);
    }

    @Test
    void hardSkillsSummaryReturnedWhenAvailable() {
        when(testResults.existsByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(true);
        when(hardSkillsSummaries.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.of(
            HardSkillsSummary.create(CANDIDATE, OFFER_ID, "fr hard", "en hard", Instant.now())));

        var result = useCase.execute(CANDIDATE, OFFER_ID, RECRUITER);

        assertThat(result.hardSkills().available()).isTrue();
        assertThat(result.hardSkills().textFr()).isEqualTo("fr hard");
    }
}
