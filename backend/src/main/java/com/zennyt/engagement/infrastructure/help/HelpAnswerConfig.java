package com.zennyt.engagement.infrastructure.help;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.engagement.application.port.HelpAnswerPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Sans clé, aucun service de redaction : l'assistant sert alors l'extrait tel quel.
 * Moins fluide, mais exact — et surtout, le centre d'aide continue de repondre.
 */
@Configuration
public class HelpAnswerConfig {
    @Bean
    HelpAnswerPort helpAnswerPort(
            ObjectMapper objectMapper,
            @Value("${groq.api-key:${GROQ_API_KEY:}}") String apiKey,
            @Value("${groq.model:openai/gpt-oss-120b}") String model,
            @Value("${groq.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${groq.read-timeout-ms:20000}") int readTimeoutMs) {
        if (apiKey == null || apiKey.isBlank()) {
            return (question, extraits, tutoyer) -> null;
        }
        return new GroqHelpAnswerPort(objectMapper, apiKey, model, connectTimeoutMs, readTimeoutMs);
    }
}
