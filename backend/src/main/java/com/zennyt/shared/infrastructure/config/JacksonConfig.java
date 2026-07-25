package com.zennyt.shared.infrastructure.config;

import org.openapitools.jackson.nullable.JsonNullableModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Enregistre le module Jackson {@link JsonNullableModule} dans l'ObjectMapper MVC.
 *
 * <p>Sans lui, tout DTO utilisant {@code JsonNullable} (sémantique tri-état des
 * PATCH, ex. {@code UpdateJobOfferRequest.assessmentId}) est indésérialisable :
 * Jackson lève une InvalidDefinitionException et la requête part en 500.
 */
@Configuration
public class JacksonConfig {

    @Bean
    public JsonNullableModule jsonNullableModule() {
        return new JsonNullableModule();
    }
}
