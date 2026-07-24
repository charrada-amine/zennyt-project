package com.zennyt.recruitment.application;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Maintient la projection locale de sécurité sans appel direct au module Identity.
 *
 * <p>Traitée <b>après commit</b> de la transaction Identity, dans une transaction
 * indépendante ({@code REQUIRES_NEW}) : une panne de projection ne rollback pas
 * l'utilisateur Identity. {@code fallbackExecution = true} conserve le rejeu du
 * snapshot de démarrage publié hors transaction. Mécanisme in-process, non durable.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class IdentityAccessStateListener {
    private final IdentityAccessStateProjector projector;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(UserAccessStateChangedEvent event) {
        try {
            projector.project(event);
        } catch (RuntimeException failure) {
            // Le snapshot Identity de démarrage réconcilie cette projection au prochain boot.
            log.error("Projection Recruitment Identity échouée pour l'événement {}",
                event.eventId(), failure);
        }
    }
}
