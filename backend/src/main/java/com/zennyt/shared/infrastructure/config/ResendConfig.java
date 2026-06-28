package com.zennyt.shared.infrastructure.config;

import com.resend.Resend;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration du client Resend (envoi d'e-mails transactionnels).
 *
 * <p>La clé API est injectée depuis l'environnement (jamais commitée). Le bean
 * reste dans la couche infrastructure : le domaine et l'application ne
 * connaissent que le port {@code EmailPort}. Le client se construit même si la
 * clé est vide (l'échec n'arrive qu'au moment de l'envoi).
 */
@Configuration
public class ResendConfig {

    @Bean
    public Resend resend(@Value("${resend.api-key:}") String apiKey) {
        return new Resend(apiKey);
    }
}
