package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
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
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Rattrape les paires (candidat, offre) qui n'ont jamais reçu de Fit Score.
 *
 * <p>Les 3 déclencheurs existants (partie jouée, offre publiée, test soumis) sont
 * volontairement bornés à 20 paires : ce sont des « aperçus rapides », pas une garantie
 * de couverture. Au-delà d'une vingtaine d'offres ou de candidats, certaines paires ne
 * rentraient dans aucun de ces lots et restaient <b>définitivement</b> sans score. Ce
 * balayage est ce qui garantit qu'aucune paire n'est oubliée pour de bon : il ne
 * s'arrête pas tant qu'il reste une paire en attente.
 *
 * <p>Reprend la forme de {@code ApplicationEventRetryWorker} (contexte Engagement) :
 * intervalle fixe, lot borné, tolérance aux échecs. Le lot est borné pour ne pas
 * monopoliser la base partagée avec le trafic utilisateur, pas parce que le calcul
 * serait lent.
 */
@Component
public class FitScoreBackfillWorker {
    private static final Logger log = LoggerFactory.getLogger(FitScoreBackfillWorker.class);

    private final FitScoreRepository fitScores;
    private final JobOfferRepository offers;
    private final RecomputeFitScoresUseCase recompute;
    private final int batchSize;
    private final Counter pairsRecomputed;
    private final Timer passDuration;

    public FitScoreBackfillWorker(FitScoreRepository fitScores,
                                  JobOfferRepository offers,
                                  RecomputeFitScoresUseCase recompute,
                                  MeterRegistry registry,
                                  @Value("${recruitment.fitscore-backfill.batch-size:200}") int batchSize) {
        this.fitScores = fitScores;
        this.offers = offers;
        this.recompute = recompute;
        this.batchSize = batchSize;
        this.pairsRecomputed = Counter.builder("recruitment.fitscore.backfill.pairs")
            .description("Paires (candidat, offre) rattrapées par le balayage de fond")
            .register(registry);
        // Un passage qui approche l'intervalle de planification signale que le lot est
        // trop gros pour le budget BDD disponible — signal d'alerte avant dégradation.
        this.passDuration = Timer.builder("recruitment.fitscore.backfill.pass")
            .description("Durée d'un passage du balayage de rattrapage")
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

    private void runOnePass() {
        List<FitScoreRepository.PairNeedingScore> pending =
            new ArrayList<>(fitScores.findPairsNeedingScore(batchSize));
        int remaining = batchSize - pending.size();
        if (remaining > 0) pending.addAll(fitScores.findStalePairs(remaining));
        if (pending.isEmpty()) return;

        Map<UUID, JobOffer> offersById = offers.findByIds(
                pending.stream().map(FitScoreRepository.PairNeedingScore::jobOfferId).distinct().toList())
            .stream().collect(Collectors.toMap(JobOffer::id, Function.identity()));

        List<RecomputeFitScoresUseCase.Pair> pairs = pending.stream()
            .map(pair -> {
                JobOffer offer = offersById.get(pair.jobOfferId());
                if (offer == null) {
                    // Offre supprimée entre la sélection et le chargement — le passage
                    // suivant ne la reverra pas, rien à rattraper.
                    log.warn("[FitScore backfill] Offre {} introuvable, paire ignorée", pair.jobOfferId());
                    return null;
                }
                return new RecomputeFitScoresUseCase.Pair(pair.candidateId(), offer);
            })
            .filter(Objects::nonNull)
            .toList();
        if (pairs.isEmpty()) return;

        try {
            int written = recompute.recomputeBatch(pairs).size();
            pairsRecomputed.increment(written);
            log.info("[FitScore backfill] {} paire(s) (re)calculée(s)", written);
        } catch (RuntimeException failure) {
            // Un lot en échec ne doit pas tuer le planificateur : les paires restent
            // sans score et seront resélectionnées au passage suivant.
            log.warn("[FitScore backfill] Lot en échec, nouvel essai au prochain passage", failure);
        }
    }
}
