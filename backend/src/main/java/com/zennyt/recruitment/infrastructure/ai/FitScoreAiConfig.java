package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
public class FitScoreAiConfig {
    @Bean
    FitScoreCalculatorPort fitScoreCalculator(
            ObjectMapper objectMapper,
            @Value("${groq.api-key:}") String apiKey,
            @Value("${groq.model:llama-3.3-70b-versatile}") String model,
            @Value("${groq.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${groq.read-timeout-ms:20000}") int readTimeoutMs,
            @Value("${recruitment.fitscore.engine:deterministic}") String engine) {
        FitScoreCalculatorPort aiCalculator = (apiKey == null || apiKey.isBlank())
            ? new StubFitScoreCalculator()
            : new GroqFitScoreCalculator(objectMapper, apiKey, model, connectTimeoutMs, readTimeoutMs);
        // D3 (PLAN_FITSCORE_V3.md) — formule déterministe par défaut ; l'IA reste
        // le moteur de repli pour les offres pas encore reliées au référentiel
        // de métiers, et reste sélectionnable seule via cette propriété.
        return "groq".equalsIgnoreCase(engine) ? aiCalculator : new DeterministicFitScoreCalculator(aiCalculator);
    }

    @Bean(name = "recruitmentFitScoreExecutor")
    Executor recruitmentFitScoreExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(200);
        executor.setThreadNamePrefix("recruitment-fit-");
        executor.initialize();
        return executor;
    }
}
