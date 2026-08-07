package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;

/**
 * Point d'entrée unique pour enfiler du travail Fit Score.
 *
 * <p>Sa seule vraie responsabilité est de garantir que le worker n'est réveillé
 * qu'<b>après le commit</b> de la transaction qui a enfilé. Réveiller pendant la
 * transaction laisse le worker lire la file avant que la ligne n'y soit visible : il ne
 * trouve rien, se rendort, et le travail attend le prochain passage périodique. Le bug est
 * intermittent, dépend du timing, et se reproduit très mal — d'où ce point de passage
 * obligé plutôt qu'un appel direct au worker depuis chaque site d'enfilement.
 */
@Component
public class FitScoreEnqueuer {
    private static final Logger log = LoggerFactory.getLogger(FitScoreEnqueuer.class);

    private final FitScoreWorkQueueRepository queue;
    private final FitScoreQueueWorker worker;
    private final boolean enabled;

    public FitScoreEnqueuer(FitScoreWorkQueueRepository queue,
                            FitScoreQueueWorker worker,
                            @Value("${recruitment.fitscore.queue.enabled:false}") boolean enabled) {
        this.queue = queue;
        this.worker = worker;
        this.enabled = enabled;
    }

    public void enqueueUrgent(List<CandidateOfferPair> pairs) {
        enqueue(pairs, FitScoreWorkQueueRepository.PRIORITY_URGENT);
    }

    public void enqueueNormal(List<CandidateOfferPair> pairs) {
        enqueue(pairs, FitScoreWorkQueueRepository.PRIORITY_NORMAL);
    }

    private void enqueue(List<CandidateOfferPair> pairs, int priority) {
        if (!enabled || pairs.isEmpty()) return;
        try {
            int inserees = queue.enqueue(pairs, priority);
            if (inserees > 0) reveillerApresCommit();
        } catch (RuntimeException failure) {
            // Enfiler est une optimisation, jamais une garantie : un échec ici ne doit pas
            // faire échouer l'opération métier qui l'a déclenché.
            log.warn("[FitScore file] Enfilement abandonné ({} paire(s)) : {}",
                pairs.size(), failure.toString());
        }
    }

    private void reveillerApresCommit() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { worker.reveiller(); }
            });
        } else {
            // Hors transaction : la ligne est déjà visible, réveil immédiat.
            worker.reveiller();
        }
    }
}
