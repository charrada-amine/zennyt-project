package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.AnswerHelpQuestionUseCase;
import com.zennyt.engagement.domain.event.HelpQuestionAskedEvent;
import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Declenche la reponse de l'assistant apres qu'une question a ete enregistree.
 *
 * <p>Apres validation, et de maniere asynchrone : une transaction annulee ne doit rien
 * declencher, et une generation de texte n'a pas a retenir la requete de l'utilisateur.
 *
 * <p>Le public est deduit du role de l'auteur, jamais de ce que le message raconte. Un
 * candidat qui ecrit « en tant que recruteur, comment... » reste un candidat : sans cela,
 * la documentation reservee aux recruteurs deviendrait accessible sur simple demande.
 */
@Component
@RequiredArgsConstructor
public class HelpAssistantListener {

    private static final Logger log = LoggerFactory.getLogger(HelpAssistantListener.class);

    private final AnswerHelpQuestionUseCase repondre;
    private final EngagementActorRepository acteurs;

    @Async("engagementHelpExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(HelpQuestionAskedEvent evenement) {
        try {
            HelpArticle.Audience audience = acteurs.findById(evenement.askedBy())
                .map(acteur -> "RECRUITER".equals(acteur.role())
                    ? HelpArticle.Audience.RECRUITER
                    : HelpArticle.Audience.CANDIDATE)
                .orElse(HelpArticle.Audience.CANDIDATE);

            repondre.repondre(evenement.helpChatId(), evenement.question(), audience, "fr");
        } catch (Exception exception) {
            // Une reponse manquante est desagreable ; une exception qui remonte ici ferait
            // echouer un traitement asynchrone sans que personne ne le voie.
            log.warn("[Aide] La reponse de l'assistant n'a pas pu etre produite", exception);
        }
    }
}
