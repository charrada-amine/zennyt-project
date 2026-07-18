package com.zennyt.engagement.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Maintient une projection locale de sécurité sans appel direct au module Identity.
 *
 * <p>La projection est mise à jour <b>après le commit</b> de la transaction Identity
 * qui publie l'événement, dans une transaction indépendante ({@code REQUIRES_NEW}) :
 * une panne de projection ne rollback donc jamais l'utilisateur Identity déjà
 * persisté. {@code fallbackExecution = true} conserve le rejeu du snapshot de
 * démarrage, publié hors transaction par {@code IdentityAccessSnapshotPublisher}.
 *
 * <p>Mécanisme in-process et non durable : pas de broker ni d'outbox ici.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class EngagementIdentityAccessStateListener {
    private final EngagementIdentityAccessStateProjector projector;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(UserAccessStateChangedEvent event) {
        try {
            projector.project(event);
        } catch (RuntimeException failure) {
            // Le snapshot Identity de démarrage réconcilie cette projection au prochain boot.
            log.error("Projection Engagement Identity échouée pour l'événement {}",
                event.eventId(), failure);
        }
    }
}
