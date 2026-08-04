package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.JobRoleProfileResolver;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Calcule et upsert les scores par paire dans des lots volontairement bornés. */
@Service
public class RecomputeFitScoresUseCase {
    private static final Logger log = LoggerFactory.getLogger(RecomputeFitScoresUseCase.class);
    public static final int MAX_BATCH_SIZE = 20;

    public record Pair(UUID candidateId, JobOffer offer) {}

    private final FitScoreCalculatorPort calculator;
    private final FitScoreRepository fitScores;
    private final JobOfferRepository offers;
    private final SoftSkillsProjectionRepository softSkills;
    private final JobRoleProfileResolver roleProfileResolver;
    private final TestResultRepository testResults;

    public RecomputeFitScoresUseCase(FitScoreCalculatorPort calculator,
                                     FitScoreRepository fitScores,
                                     JobOfferRepository offers,
                                     SoftSkillsProjectionRepository softSkills,
                                     JobRoleProfileResolver roleProfileResolver,
                                     TestResultRepository testResults) {
        this.calculator = calculator;
        this.fitScores = fitScores;
        this.offers = offers;
        this.softSkills = softSkills;
        this.roleProfileResolver = roleProfileResolver;
        this.testResults = testResults;
    }

    /**
     * Recalcul d'une paire, chargement paire par paire — chemin des 3 déclencheurs
     * existants (partie jouée, offre publiée, test de compétences soumis).
     *
     * <p>Coûte 8 allers-retours BDD (6 lectures, 1 upsert, 1 relecture) : acceptable à
     * l'unité, prohibitif en masse. Le balayage de rattrapage utilise
     * {@link #recomputeBatch} qui produit exactement le même résultat en préchargeant
     * tout le lot d'un coup — voir {@code RecomputeFitScoresUseCaseBatchTest}.
     */
    public FitScore recompute(UUID candidateId, JobOffer offer) {
        Map<String, FitScoreCalculatorPort.ModuleScore> softScores = softScoresByModule(softSkills.findByCandidateId(candidateId));
        JobRoleProfile roleProfile = roleProfileResolver.resolve(offer);
        Integer hardSkillScore = testResults.findByCandidateIdAndJobOfferId(candidateId, offer.id())
            .map(TestResult::percentage).orElse(null);
        UUID existingId = fitScores.findByCandidateIdAndJobOfferId(candidateId, offer.id())
            .map(FitScore::id).orElse(null);
        FitScore computed =
            score(candidateId, offer, softScores, roleProfile, hardSkillScore, existingId);
        return computed == null ? null : fitScores.save(computed);
    }

    /**
     * Recalcul par lot — précharge chaque type de donnée en une requête pour tout le lot,
     * puis applique le même calcul que {@link #recompute}. Utilisé uniquement par le
     * balayage de rattrapage ; les 3 déclencheurs existants ne passent jamais ici.
     *
     * @return les scores calculés (déjà écrits), dans l'ordre des paires fournies
     */
    public List<FitScore> recomputeBatch(List<Pair> pairs) {
        if (pairs.isEmpty()) return List.of();
        List<UUID> candidateIds = pairs.stream().map(Pair::candidateId).distinct().toList();
        List<JobOffer> offers = pairs.stream().map(Pair::offer)
            .collect(Collectors.toMap(JobOffer::id, Function.identity(), (a, b) -> a))
            .values().stream().toList();
        List<UUID> offerIds = offers.stream().map(JobOffer::id).toList();

        Map<UUID, Map<String, FitScoreCalculatorPort.ModuleScore>> softScoresByCandidate = softSkills.findByCandidateIds(candidateIds).stream()
            .collect(Collectors.groupingBy(SoftSkillsProjection::candidateId,
                Collectors.collectingAndThen(Collectors.toList(),
                    RecomputeFitScoresUseCase::softScoresByModule)));
        Map<UUID, JobRoleProfile> roleProfileByOffer = roleProfileResolver.resolveAll(offers);
        Map<String, Integer> hardScoreByPair = testResults
                .findByCandidateIdsAndJobOfferIds(candidateIds, offerIds).stream()
            .collect(Collectors.toMap(
                result -> pairKey(result.candidateId(), result.jobOfferId()),
                TestResult::percentage, (a, b) -> a));
        Map<String, UUID> existingIdByPair = fitScores
                .findByCandidateIdsAndJobOfferIds(candidateIds, offerIds).stream()
            .collect(Collectors.toMap(
                existing -> pairKey(existing.candidateId(), existing.jobOfferId()),
                FitScore::id, (a, b) -> a));

        List<FitScore> computed = new ArrayList<>(pairs.size());
        for (Pair pair : pairs) {
            String key = pairKey(pair.candidateId(), pair.offer().id());
            FitScore result = score(pair.candidateId(), pair.offer(),
                softScoresByCandidate.getOrDefault(pair.candidateId(), Map.of()),
                roleProfileByOffer.get(pair.offer().id()),
                hardScoreByPair.get(key),
                existingIdByPair.get(key));
            // null = offre sans métier approuvé, donc incalculable : on n'écrit rien
            // plutôt que d'inventer un score. Le balayage l'exclut déjà en amont.
            if (result != null) computed.add(result);
        }
        fitScores.saveAll(computed);
        return computed;
    }

    /**
     * Calcul pur — aucune E/S. Unique implémentation de la formule, partagée par le
     * chemin unitaire et le chemin par lot : c'est ce qui garantit qu'ils ne peuvent
     * pas diverger.
     */
    private FitScore score(UUID candidateId, JobOffer offer,
                           Map<String, FitScoreCalculatorPort.ModuleScore> softScores,
                           JobRoleProfile roleProfile, Integer hardSkillScore,
                           UUID existingId) {
        var inputs = new FitScoreCalculatorPort.FitScoreInputs(softScores, roleProfile, hardSkillScore);
        var result = calculator.calculate(inputs);
        // null = offre sans métier approuvé, ou aucun module pesant mesuré (F02) :
        // incalculable, rien n'est écrit plutôt que d'inventer un score.
        if (result == null) return null;
        return FitScore.calculated(existingId, candidateId, offer.id(),
            result.score(), result.softSkillScore(),
            hardSkillScore, result.coverageRatio(), Instant.now());
    }

    /**
     * Score <b>et couverture</b> par module CdC déjà mesuré (clé = nom du module
     * Games, ex. "MOVE_FAST") — transportés tels quels jusqu'au calculateur, qui
     * seul connaît la pondération de l'offre et peut donc pondérer par module
     * (CdC §3.2) et appliquer la couverture avant agrégation (§3.3 mécanisme 1).
     * Aplatir ici en une moyenne unique, comme avant, rendait cette pondération
     * mathématiquement sans effet : voir DeterministicFitScoreCalculator.
     */
    private static Map<String, FitScoreCalculatorPort.ModuleScore> softScoresByModule(
            List<SoftSkillsProjection> modules) {
        return modules.stream().collect(Collectors.toMap(
            SoftSkillsProjection::module,
            m -> new FitScoreCalculatorPort.ModuleScore(m.score(), m.coverageRatio()),
            (a, b) -> b));
    }

    private static String pairKey(UUID candidateId, UUID jobOfferId) {
        return candidateId + "|" + jobOfferId;
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
