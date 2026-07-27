package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.port.EmbeddingPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class EmbeddingConfig {
    @Bean
    EmbeddingPort embeddingPort(
            ObjectMapper objectMapper,
            @Value("${embedding.huggingface.api-key:}") String apiKey,
            @Value("${embedding.huggingface.model:intfloat/multilingual-e5-small}") String model,
            @Value("${embedding.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${embedding.read-timeout-ms:15000}") int readTimeoutMs) {
        if (apiKey == null || apiKey.isBlank()) return new NoOpEmbeddingPort();
        return new HuggingFaceEmbeddingPort(objectMapper, model, apiKey, connectTimeoutMs, readTimeoutMs);
    }
}
