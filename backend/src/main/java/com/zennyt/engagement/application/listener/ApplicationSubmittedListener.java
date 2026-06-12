package com.zennyt.engagement.application.listener;

import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Réaction du contexte Engagement à un événement du contexte Recruitment.
 *
 * <p>C'est LA démonstration du découplage : Engagement écoute
 * {@link ApplicationSubmittedEvent} sans que Recruitment ne sache qu'Engagement
 * existe. Recruitment publie, Engagement réagit.
 *
 * <p>Aujourd'hui : {@code @EventListener} en mémoire (in-process).
 * Le jour où Engagement devient un microservice séparé, on remplace simplement
 * cette annotation par un consumer Azure Service Bus — la méthode ne change pas.
 *
 * <p>{@code @TransactionalEventListener} garantit que la réaction n'a lieu
 * qu'après le commit de la transaction qui a produit l'événement.
 */
@Component
public class ApplicationSubmittedListener {

    @TransactionalEventListener
    public void on(ApplicationSubmittedEvent event) {
        // 1. Créer la conversation candidat <-> recruteur liée à la candidature
        // 2. Notifier le recruteur (push / SignalR)
        // (implémentation à venir par le Squad Engagement)
        System.out.printf("Engagement réagit à %s (application=%s)%n",
            event.eventType(), event.applicationId());
    }
}
