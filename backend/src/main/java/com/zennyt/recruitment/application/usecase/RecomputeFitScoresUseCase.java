package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.JobRoleProfileResolver;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Calcule et upsert les scores par paire dans des lots volontairement bornés. */
@Service
public class RecomputeFitScoresUseCase {
    private static final Logger log = LoggerFactory.getLogger(RecomputeFitScoresUseCase.class);
    public static final int MAX_BATCH_SIZE = 20;

    /**
     * D5 (PLAN_FITSCORE_V3.md) — pas de suivi de couverture par module côté
     * Games aujourd'hui ; fixé à 100% jusqu'à ce que le référentiel de jeux
     * l'expose réellement. Câblé dans la formule (voir DeterministicFitScoreCalculator)
     * pour s'activer automatiquement sans nouvelle migration le jour venu.
     */
    private static final int DEFAULT_COVERAGE_RATIO = 100;

    public record Pair(UUID candidateId, JobOffer offer) {}

    private final FitScoreCalculatorPort calculator;
    private final FitScoreRepository fitScores;
    private final JobOfferRepository offers;
    private final SoftSkillsProjectionRepository softSkills;
    private final RecruitmentActorRepository actors;
    private final JobRoleProfileResolver roleProfileResolver;
    private final TestResultRepository testResults;

    public RecomputeFitScoresUseCase(FitScoreCalculatorPort calculator,
                                     FitScoreRepository fitScores,
                                     JobOfferRepository offers,
                                     SoftSkillsProjectionRepository softSkills,
                                     RecruitmentActorRepository actors,
                                     JobRoleProfileResolver roleProfileResolver,
                                     TestResultRepository testResults) {
        this.calculator = calculator;
        this.fitScores = fitScores;
        this.offers = offers;
        this.softSkills = softSkills;
        this.actors = actors;
        this.roleProfileResolver = roleProfileResolver;
        this.testResults = testResults;
    }

    public FitScore recompute(UUID candidateId, JobOffer offer) {
        var modules = softSkills.findByCandidateId(candidateId);
        int softScore = modules.isEmpty() ? 0
            : (int) Math.round(modules.stream().mapToInt(p -> p.score()).average().orElse(0));
        String companyInfo = actors.findById(offer.recruiterId())
            .map(actor -> actor.companyInfo()).orElse(null);
        JobRoleProfile roleProfile = roleProfileResolver.resolve(offer);
        Integer hardSkillScore = testResults.findByCandidateIdAndJobOfferId(candidateId, offer.id())
            .map(TestResult::percentage).orElse(null);

        var inputs = new FitScoreCalculatorPort.FitScoreInputs(
            Map.of("games", (double) softScore),
            null, // PROVISOIRE — CV fourni plus tard par un event ProfileUpdated Identity.
            offer.description(), companyInfo, roleProfile, hardSkillScore, DEFAULT_COVERAGE_RATIO);
        var result = calculator.calculate(inputs);
        UUID existingId = fitScores.findByCandidateIdAndJobOfferId(candidateId, offer.id())
            .map(FitScore::id).orElse(null);
        return fitScores.save(FitScore.calculated(existingId, candidateId, offer.id(),
            result.score(), result.softSkillScore(), result.cvMatchScore(),
            hardSkillScore, DEFAULT_COVERAGE_RATIO, Instant.now()));
    }

    /**
     * Recalcul synchrone d'une offre (levier démo — le flux normal est
     * asynchrone via les listeners). Tolérant aux échecs par paire : un quota
     * Groq dépassé est loggé et n'interrompt pas le lot.
     */
    public int recomputeForOffer(UUID jobOfferId) {
        int written = 0;
        for (Pair pair : pairsForOffer(jobOfferId)) {
            if (recomputeQuietly(pair)) written++;
        }
        return written;
    }

    /** Recalcul synchrone de toutes les offres ACTIVE (bornées par lot). */
    public int recomputeAllActive() {
        int written = 0;
        for (JobOffer offer : offers.search(null, null, null, null, null, null, null, null,
                null, 0, MAX_BATCH_SIZE)) {
            for (Pair pair : pairsForOffer(offer.id())) {
                if (recomputeQuietly(pair)) written++;
            }
        }
        return written;
    }

    private boolean recomputeQuietly(Pair pair) {
        try {
            recompute(pair.candidateId(), pair.offer());
            return true;
        } catch (Exception e) {
            log.warn("[FitScore] Échec du calcul pour candidat={} offre={} : {}",
                pair.candidateId(), pair.offer().id(), e.getMessage());
            return false;
        }
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
