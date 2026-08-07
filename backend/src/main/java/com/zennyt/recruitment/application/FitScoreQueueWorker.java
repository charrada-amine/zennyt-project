package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository;
import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository.QueuedPair;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

/**
 * Consomme la file de travail du Fit Score.
 *
 * <p>Deux façons de se réveiller, complémentaires : le {@link #reveiller()} déclenché
 * après un enfilement (latence de quelques millisecondes) et un passage périodique de
 * sécurité (au cas où un réveil serait perdu). Le premier fait le travail en régime
 * normal, le second garantit qu'aucune ligne ne dort indéfiniment.
 *
 * <p>Le réveil in-process suffit tant que l'application tourne en une instance. Le passage
 * à {@code pg_notify} ne changerait que cette classe, pas le reste — inutile de payer
 * d'avance un coût multi-instance qui n'existe peut-être jamais.
 */
@Component
public class FitScoreQueueWorker {
    private static final Logger log = LoggerFactory.getLogger(FitScoreQueueWorker.class);

    private final FitScoreWorkQueueRepository queue;
    private final JobOfferRepository offers;
    private final InlineFitScoreWriter writer;
    private final boolean enabled;
    private final int chunkSize;
    private final int maxAttempts;

    /** Un seul permis : plusieurs réveils rapprochés déclenchent un seul passage. */
    private final Semaphore reveil = new Semaphore(0);

    /** Délimite la transaction d'une tranche — voir {@link #consommer()}. */
    private final TransactionTemplate transactions;

    public FitScoreQueueWorker(FitScoreWorkQueueRepository queue,
                               JobOfferRepository offers,
                               InlineFitScoreWriter writer,
                               MeterRegistry meters,
                               @Value("${recruitment.fitscore.queue.enabled:false}") boolean enabled,
                               @Value("${recruitment.fitscore.queue.chunk-size:200}") int chunkSize,
                               PlatformTransactionManager transactionManager,
                               @Value("${recruitment.fitscore.queue.max-attempts:5}") int maxAttempts) {
        this.queue = queue;
        this.offers = offers;
        this.writer = writer;
        this.enabled = enabled;
        this.chunkSize = chunkSize;
        this.maxAttempts = maxAttempts;
        this.transactions = new TransactionTemplate(transactionManager);

        Gauge.builder("fitscore.queue.depth", () -> queue.depth(FitScoreWorkQueueRepository.PRIORITY_URGENT))
            .tag("priority", "urgent").description("Paires urgentes en attente").register(meters);
        Gauge.builder("fitscore.queue.depth", () -> queue.depth(FitScoreWorkQueueRepository.PRIORITY_NORMAL))
            .tag("priority", "normal").description("Paires de rattrapage en attente").register(meters);
        Gauge.builder("fitscore.queue.oldest_age", queue::oldestPendingAgeSeconds)
            .description("Âge en secondes de la plus ancienne paire en attente").register(meters);
        Gauge.builder("fitscore.queue.failed", queue::failedCount)
            .description("Paires abandonnées — signal de bug, à alerter").register(meters);
    }

    /** Réveil immédiat après un enfilement. */
    public void reveiller() {
        reveil.release();
    }

    /**
     * Boucle de consommation. L'attente sur le sémaphore rend le worker réactif sans
     * interroger la base en permanence : file vide = aucune requête, aucun CPU.
     */
    @Scheduled(fixedDelayString = "${recruitment.fitscore.queue.poll-interval-ms:5000}")
    public void consommer() {
        if (!enabled) return;
        try {
            // Consomme le signal s'il y en a un, sinon repart quand même : le passage
            // périodique sert de filet si un réveil s'est perdu.
            reveil.tryAcquire(1, TimeUnit.MILLISECONDS);
            reveil.drainPermits();
            int traites;
            do {
                // Une transaction par tranche. Elle englobe la réservation ET le traitement :
                // c'est indispensable pour que SKIP LOCKED protège réellement. Les verrous
                // ne durent que le temps de la transaction — si elle se refermait juste
                // après la réservation, un autre worker retrouverait les mêmes lignes
                // encore en attente et les traiterait une seconde fois.
                // Effet secondaire recherché : un worker tué en plein traitement laisse ses
                // lignes revenir automatiquement en attente, sans mécanisme de reprise.
                Integer resultat = transactions.execute(status -> unPassage());
                traites = resultat == null ? 0 : resultat;
            } while (traites == chunkSize);   // file encore pleine : on enchaîne
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
        } catch (RuntimeException failure) {
            // Un passage raté ne doit jamais tuer le worker.
            log.warn("[FitScore file] Passage abandonné : {}", failure.toString());
        }
    }

    private int unPassage() {
        List<QueuedPair> reserves = queue.claim(chunkSize);
        if (reserves.isEmpty()) return 0;

        Map<UUID, JobOffer> offresParId = chargerOffres(reserves);
        List<RecomputeFitScoresUseCase.Pair> aCalculer = new ArrayList<>();
        List<Long> traitees = new ArrayList<>();

        for (QueuedPair reserve : reserves) {
            JobOffer offer = offresParId.get(reserve.pair().jobOfferId());
            if (offer == null) {
                // Offre supprimée entre l'enfilement et le traitement : rien à calculer,
                // et rien à réessayer non plus.
                traitees.add(reserve.id());
                continue;
            }
            aCalculer.add(new RecomputeFitScoresUseCase.Pair(reserve.pair().candidateId(), offer));
            traitees.add(reserve.id());
        }

        if (!aCalculer.isEmpty()) {
            try {
                writer.computeAndPersist(aCalculer);
            } catch (RuntimeException failure) {
                // Échec du lot : chaque ligne repart en backoff plutôt que d'être perdue.
                reserves.forEach(r -> queue.fail(r.id(), failure.toString(), maxAttempts));
                return reserves.size();
            }
        }
        queue.complete(traitees);
        log.debug("[FitScore file] {} paire(s) traitée(s)", traitees.size());
        return reserves.size();
    }

    private Map<UUID, JobOffer> chargerOffres(List<QueuedPair> reserves) {
        List<UUID> ids = reserves.stream().map(r -> r.pair().jobOfferId()).distinct().toList();
        Map<UUID, JobOffer> parId = new java.util.HashMap<>();
        for (UUID id : ids) {
            Optional<JobOffer> offer = offers.findById(id);
            offer.ifPresent(value -> parId.put(id, value));
        }
        return parId;
    }
}
