package com.zennyt.recruitment.infrastructure;

import com.zennyt.recruitment.domain.event.OtpRequestedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Canal de livraison OTP du profil {@code dev} : trace le code en clair dans le log
 * applicatif, faute de passerelle SMS/e-mail branchée en local.
 *
 * <p>Sans ce composant l'événement {@link OtpRequestedEvent} n'a aucun consommateur
 * et le code (jamais persisté en clair) est perdu — les tunnels OTP deviennent
 * invérifiables de bout en bout en dev.
 */
@Component
@Profile("dev")
public class DevOtpDeliveryLogger {

    private static final Logger log = LoggerFactory.getLogger(DevOtpDeliveryLogger.class);

    @EventListener
    public void on(OtpRequestedEvent event) {
        log.info("[DEV OTP] purpose={} resourceId={} recipient={} code={} (expire {})",
            event.purpose(), event.resourceId(), event.recipientUserId(),
            event.oneTimeCode(), event.expiresAt());
    }
}
