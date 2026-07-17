package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Calcule et upsert les scores par paire dans des lots volontairement bornés. */
@Service
public class RecomputeFitScoresUseCase {
    public static final int MAX_BATCH_SIZE = 20;
    public record Pair(UUID candidateId, JobOffer offer) {}

    private final FitScoreCalculatorPort calculator;
    private final FitScoreRepository fitScores;
    private final JobOfferRepository offers;
    private final SoftSkillsProjectionRepository softSkills;

    public RecomputeFitScoresUseCase(FitScoreCalculatorPort calculator,
                                     FitScoreRepository fitScores,
                                     JobOfferRepository offers,
                                     SoftSkillsProjectionRepository softSkills) {
        this.calculator = calculator;
        this.fitScores = fitScores;
        this.offers = offers;
        this.softSkills = softSkills;
    }

    public FitScore recompute(UUID candidateId, JobOffer offer) {
        int softScore = softSkills.findByCandidateId(candidateId).map(p -> p.score()).orElse(0);
        var inputs = new FitScoreCalculatorPort.FitScoreInputs(
            Map.of("games", (double) softScore),
            null, // PROVISOIRE — CV fourni plus tard par un event ProfileUpdated Identity.
            offer.description(), offer.companyInfo());
        var result = calculator.calculate(inputs);
        UUID existingId = fitScores.findByCandidateIdAndJobOfferId(candidateId, offer.id())
            .map(FitScore::id).orElse(null);
        return fitScores.save(FitScore.calculated(existingId, candidateId, offer.id(),
            result.score(), result.softSkillScore(), result.cvMatchScore(), Instant.now()));
    }

    public java.util.List<Pair> pairsForCandidate(UUID candidateId) {
        return offers.findFeedForCandidate(candidateId, 0, MAX_BATCH_SIZE).stream()
            .map(offer -> new Pair(candidateId, offer)).toList();
    }

    public java.util.List<Pair> pairsForOffer(UUID jobOfferId) {
        return offers.findById(jobOfferId)
            .map(offer -> softSkills.findCandidateIds(MAX_BATCH_SIZE).stream()
                .map(candidateId -> new Pair(candidateId, offer)).toList())
            .orElseGet(java.util.List::of);
    }
}
