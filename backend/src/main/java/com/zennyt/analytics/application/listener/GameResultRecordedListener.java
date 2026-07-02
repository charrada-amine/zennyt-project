package com.zennyt.analytics.application.listener;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Réaction du contexte Analytics à la fin d'une session de jeu.
 *
 * <p>Point d'intégration du contexte Games avec le reste de la plateforme :
 * Analytics écoute {@link GameResultRecordedEvent} sans que Games ne sache
 * qu'Analytics existe. Games reste totalement indépendant — seul le contrat
 * d'événement les relie.
 *
 * <p>Aujourd'hui : {@code @EventListener} en mémoire. Le jour où Games ou
 * Analytics devient un microservice, on remplace l'annotation par un consumer
 * Azure Service Bus — la méthode ne change pas.
 */
@Component
public class GameResultRecordedListener {

    @TransactionalEventListener
    public void on(GameResultRecordedEvent event) {
        // Alimenter le tableau de bord cognitif du candidat (profil de planification, etc.)
        System.out.printf("Analytics enregistre %s (session=%s, score=%.1f/100, niveau=%s)%n",
            event.eventType(), event.sessionId(), event.normalizedScore(), event.level());
    }
}
