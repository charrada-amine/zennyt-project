package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicLong;

/**
 * Publie la <b>profondeur du retard</b> du Fit Score : le nombre de paires
 * (candidat actif, offre ACTIVE) sans score ou dont le score est périmé.
 *
 * <p>C'est le seul indicateur qui prévient <b>avant</b> la saturation. Un test
 * fonctionnel du type « 25 offres × 25 candidats finissent tous scorés » réussit
 * encore la veille du jour où le balayage ne suit plus le flux entrant : il valide
 * la correction du bug, il ne surveille pas la santé du système. Une profondeur de
 * retard qui croît sur plusieurs jours consécutifs, elle, signale des semaines à
 * l'avance qu'il faut revoir l'approche (voir le plan, phases 1-2).
 *
 * <p>Relevé beaucoup moins souvent que le balayage : le comptage est volontairement
 * non borné, donc coûteux. Auto-signalant — il devient lourd exactement quand le
 * retard devient important, c'est-à-dire au moment où la question se pose vraiment.
 *
 * <p>Composant distinct de {@link FitScoreBackfillWorker} : superviser et travailler
 * sont deux responsabilités, et un incident de mesure ne doit pas pouvoir gêner le
 * rattrapage lui-même.
 */
@Component
public class FitScoreBacklogMonitor {
    private static final Logger log = LoggerFactory.getLogger(FitScoreBacklogMonitor.class);

    /** {@code -1} tant qu'aucune mesure n'a abouti — à distinguer d'un retard nul. */
    private final AtomicLong backlogDepth = new AtomicLong(-1);
    private final FitScoreRepository fitScores;

    public FitScoreBacklogMonitor(FitScoreRepository fitScores, MeterRegistry registry) {
        this.fitScores = fitScores;
        Gauge.builder("recruitment.fitscore.backlog.depth", backlogDepth, AtomicLong::doubleValue)
            .description("Paires (candidat actif, offre active) sans Fit Score ou avec un score périmé")
            .register(registry);
    }

    @Scheduled(fixedDelayString = "${recruitment.fitscore-backfill.backlog-metric-interval-ms:900000}",
               initialDelayString = "${recruitment.fitscore-backfill.backlog-metric-interval-ms:900000}")
    public void measureBacklogDepth() {
        try {
            long depth = fitScores.countPairsNeedingScore();
            backlogDepth.set(depth);
            log.debug("[FitScore] Profondeur du retard : {} paire(s)", depth);
        } catch (RuntimeException failure) {
            // Une mesure ratée ne doit rien interrompre : la jauge conserve sa valeur
            // précédente plutôt que d'afficher un zéro trompeur.
            log.warn("[FitScore] Mesure de la profondeur du retard échouée", failure);
        }
    }

    /** Dernière profondeur mesurée, ou {@code -1} si aucune mesure n'a encore abouti. */
    public long lastMeasuredDepth() {
        return backlogDepth.get();
    }
}
