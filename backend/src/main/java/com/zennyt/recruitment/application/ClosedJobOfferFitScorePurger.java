package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Supprime les Fit Score d'une offre fermée.
 *
 * <p>Sans cela la table {@code fit_scores} ne fait que grossir : elle conserve
 * indéfiniment les scores d'offres que plus personne ne peut consulter, ce qui alourdit
 * l'anti-jointure du balayage de rattrapage — la requête devient alors plus coûteuse que
 * le calcul qu'elle sert à déclencher.
 *
 * <p>Composant <b>distinct</b> de {@link JobOfferFitScoreListener}, qui écoute le même
 * événement : celui-ci calcule à la publication, celui-là purge à la fermeture. Les garder
 * séparés évite de modifier un listener déjà en production pour y greffer une
 * responsabilité sans rapport.
 *
 * <p>Le statut d'une offre étant librement réversible (voir {@link JobOfferStatus}), une
 * offre rouverte se retrouve simplement sans score : le balayage la détecte comme n'importe
 * quelle paire manquante et la recalcule. Aucune perte, juste un recalcul différé.
 */
@Component
public class ClosedJobOfferFitScorePurger {
    private static final Logger log = LoggerFactory.getLogger(ClosedJobOfferFitScorePurger.class);

    private final FitScoreRepository fitScores;

    public ClosedJobOfferFitScorePurger(FitScoreRepository fitScores) {
        this.fitScores = fitScores;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(JobOfferStatusChangedEvent event) {
        if (event.newStatus() != JobOfferStatus.CLOSED) return;
        try {
            int purged = fitScores.deleteByJobOfferId(event.jobOfferId());
            if (purged > 0) {
                log.info("[FitScore] {} score(s) purgé(s) pour l'offre fermée {}",
                    purged, event.jobOfferId());
            }
        } catch (RuntimeException failure) {
            // Une purge ratée n'est pas bloquante : les scores restent, ils seront
            // repris à la prochaine fermeture ou resteront inertes (offre non ACTIVE,
            // donc jamais sélectionnée par le balayage ni affichée).
            log.warn("[FitScore] Purge échouée pour l'offre {}", event.jobOfferId(), failure);
        }
    }
}
