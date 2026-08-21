package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Choix de l'implémentation du résumé IA candidat : Groq si une clé est configurée, sinon stub. */
@Configuration
public class ResumeSummaryAiConfig {

    @Bean
    public ResumeSummaryGeneratorPort resumeSummaryGenerator(
            ObjectMapper objectMapper,
            @Value("${groq.api-key:}") String apiKey,
            @Value("${groq.model:openai/gpt-oss-120b}") String model,
            @Value("${groq.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${groq.read-timeout-ms:20000}") int readTimeoutMs) {
        if (apiKey == null || apiKey.isBlank()) return new StubResumeSummaryGenerator();
        return new GroqResumeSummaryGenerator(objectMapper, apiKey, model, connectTimeoutMs, readTimeoutMs);
    }
}
