package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Efface l'historique terminé de la file de travail Fit Score.
 *
 * <p>La file écrit une ligne par paire candidat × offre traitée et n'en efface aucune :
 * sans purge, elle croît indéfiniment, sur un volume proportionnel au <b>produit</b> des
 * candidats par les offres. Les index étant partiels sur {@code PENDING}, rien ne ralentit
 * — c'est l'espace disque qui part, silencieusement. Ce genre de croissance ne se remarque
 * qu'une fois le disque plein.
 *
 * <p>Seules les lignes {@code DONE} sont supprimées. Les {@code FAILED} sont conservées :
 * elles sont le seul témoignage d'un calcul abandonné après {@code max-attempts}, et leur
 * volume est borné par ce même réglage.
 *
 * <p>Séparé de {@link FitScoreQueueWorker} volontairement : le worker doit rester
 * concentré sur le débit et pouvoir être désactivé sans que l'historique cesse d'être
 * nettoyé. Le nettoyage tourne même quand la file est coupée — c'est justement là qu'il
 * reste un historique à évacuer.
 */
@Component
public class FitScoreQueuePurger {
    private static final Logger log = LoggerFactory.getLogger(FitScoreQueuePurger.class);

    private final FitScoreWorkQueueRepository queue;
    private final int retentionDays;

    public FitScoreQueuePurger(FitScoreWorkQueueRepository queue,
                               @Value("${recruitment.fitscore.queue.retention-days:7}") int retentionDays) {
        this.queue = queue;
        this.retentionDays = retentionDays;
    }

    /**
     * {@code fixedDelay} : un passage ne démarre qu'après la fin du précédent, jamais de
     * chevauchement. La suppression est bornée par lot côté adaptateur ; si l'historique
     * accumulé dépasse un lot, les passages suivants finissent le travail — la purge n'a
     * aucune urgence, elle doit seulement ne jamais gêner le trafic utilisateur.
     */
    @Scheduled(fixedDelayString = "${recruitment.fitscore.queue.purge-interval-ms:86400000}",
               initialDelayString = "${recruitment.fitscore.queue.purge-initial-delay-ms:300000}")
    public void purge() {
        int supprimees = queue.purgeCompletedOlderThan(retentionDays);
        if (supprimees > 0) {
            log.info("[FitScore file] {} ligne(s) terminée(s) de plus de {} jours purgée(s)",
                supprimees, retentionDays);
        }
    }
}
