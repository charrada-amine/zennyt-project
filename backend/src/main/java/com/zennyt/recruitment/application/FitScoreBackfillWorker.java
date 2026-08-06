package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Pré-remplissage : détecte les paires (candidat, offre) sans Fit Score, ou dont le score
 * est périmé, et les <b>enfile</b> pour traitement.
 *
 * <h2>Ce composant n'est plus la garantie de correction</h2>
 * Il l'était : les 3 déclencheurs étaient bornés à 20 paires, et ce balayage était le seul
 * mécanisme qui rattrapait le reste. Ce n'est plus le cas — le calcul à l'affichage
 * ({@link InlineFitScoreComputer}) garantit désormais qu'aucune offre montrée n'est sans
 * note. Le balayage est devenu une <b>optimisation</b> : il évite que ce calcul ait à
 * s'exécuter, et sert de <b>détecteur</b>.
 *
 * <p>Conséquence directe : en régime normal, ce balayage ne doit <b>rien trouver</b>. S'il
 * trouve quelque chose, c'est que les déclencheurs ont laissé passer une paire — donc un
 * bug ailleurs. D'où la métrique {@code backfill.found}, à surveiller pour ce qu'elle
 * signale, pas pour le travail qu'elle représente.
 *
 * <h2>Deadline plutôt que compteur</h2>
 * Le passage boucle par tranches jusqu'à épuisement ou jusqu'à sa deadline. La taille de
 * tranche redevient ce qu'elle aurait toujours dû être — une granularité de transaction,
 * pas un plafond de débit. Un budget de temps reste valable quand le matériel change ; un
 * compteur de paires, non.
 */
@Component
public class FitScoreBackfillWorker {
    private static final Logger log = LoggerFactory.getLogger(FitScoreBackfillWorker.class);

    private final FitScoreRepository fitScores;
    private final FitScoreEnqueuer enqueuer;
    private final int batchSize;
    private final long deadlineMs;
    private final Counter pairsFound;
    private final Timer passDuration;

    public FitScoreBackfillWorker(FitScoreRepository fitScores,
                                  FitScoreEnqueuer enqueuer,
                                  MeterRegistry registry,
                                  @Value("${recruitment.fitscore-backfill.batch-size:200}") int batchSize,
                                  @Value("${recruitment.fitscore-backfill.deadline-ms:5000}") long deadlineMs) {
        this.fitScores = fitScores;
        this.enqueuer = enqueuer;
        this.batchSize = batchSize;
        this.deadlineMs = deadlineMs;
        // Doit valoir 0 en régime établi : toute valeur non nulle signale que les
        // déclencheurs ont laissé passer quelque chose.
        this.pairsFound = Counter.builder("recruitment.fitscore.backfill.found")
            .description("Trous détectés par le pré-remplissage — doit être 0 en régime normal")
            .register(registry);
        this.passDuration = Timer.builder("recruitment.fitscore.backfill.pass")
            .description("Durée d'un passage de pré-remplissage")
            .register(registry);
    }

    /**
     * Un passage traite d'abord les paires <b>sans</b> score (le trou de couverture, qui
     * est le bug corrigé), puis remplit le budget restant du lot avec les paires dont le
     * score est <b>périmé</b>. Les manquantes passent devant parce qu'une paire sans score
     * est toujours reléguée en fin de fil, alors qu'une paire périmée reste affichée — mal
     * classée, mais visible.
     */
    @Scheduled(fixedDelayString = "${recruitment.fitscore-backfill.interval-ms:60000}",
               initialDelayString = "${recruitment.fitscore-backfill.interval-ms:60000}")
    public void backfillMissingScores() {
        passDuration.record(this::runOnePass);
    }

    /**
     * Boucle par tranches jusqu'à épuisement ou deadline. La deadline s'évalue entre deux
     * tranches, jamais au milieu : un passage s'arrête proprement après la tranche en
     * cours, sans jamais annuler du travail déjà fait.
     */
    private void runOnePass() {
        long fin = System.nanoTime() + deadlineMs * 1_000_000L;
        int total = 0;
        while (System.nanoTime() < fin) {
            int traites = uneTranche();
            total += traites;
            if (traites < batchSize) break;   // plus rien à trouver
        }
        if (total > 0) {
            pairsFound.increment(total);
            log.info("[FitScore pré-remplissage] {} trou(s) détecté(s) et enfilé(s) — "
                + "en régime établi ce nombre doit être 0", total);
        }
    }

    private int uneTranche() {
        List<FitScoreRepository.PairNeedingScore> pending =
            new ArrayList<>(fitScores.findPairsNeedingScore(batchSize));
        int remaining = batchSize - pending.size();
        if (remaining > 0) pending.addAll(fitScores.findStalePairs(remaining));
        if (pending.isEmpty()) return 0;

        // Enfile plutôt que calculer : un seul chemin d'exécution à maintenir et à tester,
        // et le worker de la file applique les mêmes garanties (priorités, backoff, reprise
        // après redémarrage) à tout le travail, d'où qu'il vienne.
        enqueuer.enqueueNormal(pending.stream()
            .map(p -> new CandidateOfferPair(p.candidateId(), p.jobOfferId()))
            .toList());
        return pending.size();
    }
}
