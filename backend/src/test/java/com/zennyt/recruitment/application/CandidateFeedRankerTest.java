package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * Vérifie les deux règles centrales du plan "Recommended for you" : une offre
 * sans Fit Score ne dépasse jamais une offre scorée (sujet séparé, non
 * touché ici), et à l'intérieur d'un même groupe, les préférences respectées
 * et la proximité sémantique servent uniquement de bonus de tri.
 */
class CandidateFeedRankerTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID RECRUITER = UUID.randomUUID();

    private final RecruitmentActorRepository actors = mock(RecruitmentActorRepository.class);
    private final FitScoreRepository fitScores = mock(FitScoreRepository.class);
    private final JobPositionRepository positions = mock(JobPositionRepository.class);
    private final CandidateFeedRanker ranker = new CandidateFeedRanker(actors, fitScores, positions, 2.0, 2.0);

    @Test
    void scoredOfferAlwaysRanksBeforeUnscoredOfferRegardlessOfBonus() {
        JobOffer scoredButNoMatch = offer(UUID.randomUUID(), ContractType.CONTRACT, WorkplaceType.ON_SITE);
        JobOffer unscoredPerfectMatch = offer(UUID.randomUUID(), ContractType.FULL_TIME, WorkplaceType.REMOTE);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(candidate(
            WorkplaceType.REMOTE, ContractType.FULL_TIME, null, null, null)));
        when(fitScores.findByCandidateIdAndJobOfferIds(eq(CANDIDATE), any())).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, scoredButNoMatch.id(), 40, 40, null, 100, Instant.now())));
        when(positions.findByIds(any())).thenReturn(List.of());

        var ranked = ranker.rank(CANDIDATE, List.of(unscoredPerfectMatch, scoredButNoMatch));

        assertThat(ranked).extracting(JobOffer::id)
            .containsExactly(scoredButNoMatch.id(), unscoredPerfectMatch.id());
    }

    @Test
    void withinScoredBucketCriteriaMatchesBreakTies() {
        JobOffer noMatch = offer(UUID.randomUUID(), ContractType.CONTRACT, WorkplaceType.ON_SITE);
        JobOffer fullMatch = offer(UUID.randomUUID(), ContractType.FULL_TIME, WorkplaceType.REMOTE);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(candidate(
            WorkplaceType.REMOTE, ContractType.FULL_TIME, null, null, null)));
        when(fitScores.findByCandidateIdAndJobOfferIds(eq(CANDIDATE), any())).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, noMatch.id(), 80, 80, null, 100, Instant.now()),
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, fullMatch.id(), 80, 80, null, 100, Instant.now())));
        when(positions.findByIds(any())).thenReturn(List.of());

        var ranked = ranker.rank(CANDIDATE, List.of(noMatch, fullMatch));

        assertThat(ranked).extracting(JobOffer::id).containsExactly(fullMatch.id(), noMatch.id());
    }

    @Test
    void higherFitScoreStillWinsOverMorePreferenceMatches() {
        JobOffer highScoreFewMatches = offer(UUID.randomUUID(), ContractType.CONTRACT, WorkplaceType.ON_SITE);
        JobOffer lowScoreFullMatch = offer(UUID.randomUUID(), ContractType.FULL_TIME, WorkplaceType.REMOTE);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(candidate(
            WorkplaceType.REMOTE, ContractType.FULL_TIME, null, null, null)));
        when(fitScores.findByCandidateIdAndJobOfferIds(eq(CANDIDATE), any())).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, highScoreFewMatches.id(), 90, 90, null, 100, Instant.now()),
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, lowScoreFullMatch.id(), 80, 80, null, 100, Instant.now())));
        when(positions.findByIds(any())).thenReturn(List.of());

        // 90 (0 critère) vs 80 + 2*2 (2 critères) = 84 -> le vrai Fit Score l'emporte
        var ranked = ranker.rank(CANDIDATE, List.of(lowScoreFullMatch, highScoreFewMatches));

        assertThat(ranked).extracting(JobOffer::id)
            .containsExactly(highScoreFewMatches.id(), lowScoreFullMatch.id());
    }

    @Test
    void noActorProjectionYet_leavesOrderUnchanged() {
        JobOffer first = offer(UUID.randomUUID(), ContractType.FULL_TIME, WorkplaceType.REMOTE);
        JobOffer second = offer(UUID.randomUUID(), ContractType.CONTRACT, WorkplaceType.ON_SITE);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.empty());
        when(fitScores.findByCandidateIdAndJobOfferIds(eq(CANDIDATE), any())).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, first.id(), 70, 70, null, 100, Instant.now()),
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, second.id(), 70, 70, null, 100, Instant.now())));
        when(positions.findByIds(any())).thenReturn(List.of());

        var ranked = ranker.rank(CANDIDATE, List.of(first, second));

        assertThat(ranked).extracting(JobOffer::id).containsExactly(first.id(), second.id());
    }

    @Test
    void semanticSimilarityBreaksTiesWithinScoredBucket() {
        UUID matchingPositionId = UUID.randomUUID();
        UUID oppositePositionId = UUID.randomUUID();
        JobOffer closeRole = offerWithPosition(UUID.randomUUID(), matchingPositionId);
        JobOffer distantRole = offerWithPosition(UUID.randomUUID(), oppositePositionId);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(
            candidate(null, null, null, null, "[1.0,0.0]")));
        when(fitScores.findByCandidateIdAndJobOfferIds(eq(CANDIDATE), any())).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, closeRole.id(), 80, 80, null, 100, Instant.now()),
            FitScore.calculated(UUID.randomUUID(), CANDIDATE, distantRole.id(), 80, 80, null, 100, Instant.now())));
        when(positions.findByIds(any())).thenReturn(List.of(
            jobPosition(matchingPositionId, "[1.0,0.0]"), jobPosition(oppositePositionId, "[-1.0,0.0]")));

        var ranked = ranker.rank(CANDIDATE, List.of(distantRole, closeRole));

        assertThat(ranked).extracting(JobOffer::id).containsExactly(closeRole.id(), distantRole.id());
    }

    private RecruitmentActor candidate(WorkplaceType workplaceTypePreference, ContractType contractTypePreference,
                                       String targetLocation, Boolean openInternationally, String lookingForEmbedding) {
        return new RecruitmentActor(CANDIDATE, "CANDIDATE", true, "Aicha Gharbi", null, "Tunis", "Tunisie",
            null, null, workplaceTypePreference, contractTypePreference, targetLocation, openInternationally,
            null, null, lookingForEmbedding, Instant.now(), UUID.randomUUID());
    }

    private JobOffer offer(UUID id, ContractType contractType, WorkplaceType workplaceType) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(id, RECRUITER, null, "Développeur", new Location("Tunis", "TN"),
            40000.0, 70000.0, contractType, workplaceType, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, null, false, JobOfferStatus.ACTIVE, now, now);
    }

    private JobOffer offerWithPosition(UUID id, UUID jobPositionId) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(id, RECRUITER, null, "Développeur", new Location("Tunis", "TN"),
            40000.0, 70000.0, ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, jobPositionId, false, JobOfferStatus.ACTIVE, now, now);
    }

    private JobPosition jobPosition(UUID id, String embedding) {
        return JobPosition.rehydrate(id, "Développeur", "IT, AI & Fintech", JobProfileType.TECHNIQUE,
            false, JobPositionStatus.APPROVED, null, null, null, null, null, Instant.now(), embedding, null);
    }
}
