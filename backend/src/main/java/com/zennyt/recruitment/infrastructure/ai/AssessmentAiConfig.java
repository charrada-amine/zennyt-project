package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Choix de l'implémentation de génération de test IA : Groq si une clé est
 * configurée (mêmes propriétés {@code groq.api-key}/{@code groq.model} que
 * {@link FitScoreAiConfig}), sinon stub hors ligne.
 */
@Configuration
public class AssessmentAiConfig {

    @Bean
    public AssessmentGeneratorPort assessmentGenerator(
            ObjectMapper objectMapper,
            @Value("${groq.api-key:}") String apiKey,
            @Value("${groq.model:llama-3.3-70b-versatile}") String model,
            @Value("${groq.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${groq.read-timeout-ms:20000}") int readTimeoutMs) {
        if (apiKey == null || apiKey.isBlank()) return new StubAssessmentGenerator();
        return new GroqAssessmentGenerator(objectMapper, apiKey, model, connectTimeoutMs, readTimeoutMs);
    }
}
