package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Garantit qu'aucune offre affichée au candidat n'est sans note — en la calculant au
 * moment de l'affichage si elle manque.
 *
 * <p>C'est le renversement central de cette architecture. Avant, la garantie de couverture
 * venait du balayage de fond, et l'affichage subissait ses trous. Désormais l'affichage
 * garantit, et le travail de fond ne fait plus qu'<i>éviter</i> que ce calcul ait à
 * s'exécuter. Le balayage devient une optimisation, plus une condition de correction.
 *
 * <h2>Budget de temps, pas compteur de paires</h2>
 * La limite principale est {@code budgetMs} : on calcule tant qu'on est dans le budget.
 * C'est la leçon du plafond de 200 du balayage — un compteur de paires devient faux dès
 * que le matériel ou le code change, un budget de temps reste valable. Le plafond
 * {@code maxPairs} n'est qu'une ceinture de sécurité pour borner le pire cas absolu si le
 * budget était mal réglé ; il vaut la taille du pool, donc n'est jamais atteint en pratique.
 *
 * <h2>Fail-open, toujours</h2>
 * Toute défaillance du calcul se solde par un log, une métrique, et l'affichage de la liste
 * <b>sans</b> les notes manquantes — c'est-à-dire le comportement d'avant. Un incident sur
 * le calcul ne doit jamais devenir un écran d'erreur sur une route aussi fréquentée.
 */
@Component
public class InlineFitScoreComputer {
    private static final Logger log = LoggerFactory.getLogger(InlineFitScoreComputer.class);

    private final FitScoreRepository fitScores;
    private final JobRoleProfileResolver roleProfileResolver;
    private final InlineFitScoreWriter writer;
    private final boolean enabled;
    private final long budgetMs;
    private final int maxPairs;

    private final Counter pairsComputed;
    private final Counter capped;
    private final Counter failures;
    private final Timer duration;

    public InlineFitScoreComputer(FitScoreRepository fitScores,
                                  JobRoleProfileResolver roleProfileResolver,
                                  InlineFitScoreWriter writer,
                                  MeterRegistry meters,
                                  @Value("${recruitment.fitscore.inline.enabled:false}") boolean enabled,
                                  @Value("${recruitment.fitscore.inline.budget-ms:800}") long budgetMs,
                                  @Value("${recruitment.fitscore.inline.max-pairs:200}") int maxPairs) {
        this.fitScores = fitScores;
        this.roleProfileResolver = roleProfileResolver;
        this.writer = writer;
        this.enabled = enabled;
        this.budgetMs = budgetMs;
        this.maxPairs = maxPairs;
        this.pairsComputed = Counter.builder("fitscore.inline.pairs")
            .description("Paires calculées à l'affichage — doit tendre vers 0 quand le travail de fond suit")
            .register(meters);
        this.capped = Counter.builder("fitscore.inline.capped")
            .description("Affichages où le budget a été épuisé — si non nul, le travail de fond ne suit pas")
            .register(meters);
        this.failures = Counter.builder("fitscore.inline.failures")
            .description("Calculs à l'affichage en échec (fail-open déclenché)")
            .register(meters);
        this.duration = Timer.builder("fitscore.inline.duration")
            .description("Latence ajoutée aux requêtes d'affichage par le calcul inline")
            .register(meters);
    }

    /**
     * Calcule les notes manquantes du pool, dans la limite du budget.
     *
     * @return les paires laissées de côté faute de budget — à enfiler par l'appelant pour
     *         que le candidat ait une liste complète au rechargement suivant. Vide si tout
     *         a été traité, si la fonctionnalité est désactivée, ou en cas d'échec.
     */
    public List<CandidateOfferPair> ensureScored(UUID candidateId, List<JobOffer> pool) {
        if (!enabled || pool.isEmpty()) return List.of();
        long start = System.nanoTime();
        try {
            List<CandidateOfferPair> reste = computeWithinBudget(candidateId, pool);
            duration.record(System.nanoTime() - start, java.util.concurrent.TimeUnit.NANOSECONDS);
            return reste;
        } catch (RuntimeException failure) {
            // Fail-open : jamais d'erreur remontée à une requête d'affichage.
            failures.increment();
            log.warn("[FitScore inline] Calcul à l'affichage abandonné pour le candidat {} : {}",
                candidateId, failure.toString());
            return List.of();
        }
    }

    private List<CandidateOfferPair> computeWithinBudget(UUID candidateId, List<JobOffer> pool) {
        List<JobOffer> manquantes = missingAndEligible(candidateId, pool);
        if (manquantes.isEmpty()) return List.of();

        long deadline = System.nanoTime() + budgetMs * 1_000_000L;
        List<RecomputeFitScoresUseCase.Pair> aCalculer = new ArrayList<>();
        List<CandidateOfferPair> reportees = new ArrayList<>();

        for (JobOffer offer : manquantes) {
            boolean budgetRestant = System.nanoTime() < deadline;
            if (aCalculer.size() < maxPairs && budgetRestant) {
                aCalculer.add(new RecomputeFitScoresUseCase.Pair(candidateId, offer));
            } else {
                reportees.add(new CandidateOfferPair(candidateId, offer.id()));
            }
        }

        if (!aCalculer.isEmpty()) {
            writer.computeAndPersist(aCalculer);
            pairsComputed.increment(aCalculer.size());
        }
        if (!reportees.isEmpty()) {
            capped.increment();
            log.info("[FitScore inline] {} paire(s) calculée(s), {} reportée(s) faute de budget",
                aCalculer.size(), reportees.size());
        }
        return List.copyOf(reportees);
    }

    /**
     * Offres du pool sans note, et dont le métier est approuvé.
     *
     * <p>Le filtre d'éligibilité n'est pas optionnel : une offre dont le métier attend
     * l'approbation d'un admin est <i>incalculable</i>, pas « en attente de calcul ». Sans
     * ce filtre elle serait resoumise à <b>chaque affichage</b>, consommant le budget sans
     * jamais aboutir — le même piège que la boucle infinie déjà rencontrée sur le balayage,
     * en pire puisque payé à chaque requête au lieu d'une fois par passage.
     */
    private List<JobOffer> missingAndEligible(UUID candidateId, List<JobOffer> pool) {
        List<CandidateOfferPair> pairs = pool.stream()
            .map(offer -> new CandidateOfferPair(candidateId, offer.id())).toList();
        Set<UUID> dejaNotees = fitScores.findByPairs(pairs).stream()
            .map(score -> score.jobOfferId()).collect(Collectors.toSet());

        List<JobOffer> sansNote = pool.stream()
            .filter(offer -> !dejaNotees.contains(offer.id())).toList();
        if (sansNote.isEmpty()) return List.of();

        Map<UUID, JobRoleProfile> profils = roleProfileResolver.resolveAll(sansNote);
        return sansNote.stream().filter(offer -> profils.get(offer.id()) != null).toList();
    }
}
