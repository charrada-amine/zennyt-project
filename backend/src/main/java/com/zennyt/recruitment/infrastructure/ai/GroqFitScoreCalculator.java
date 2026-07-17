package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/** Adaptateur Groq du calcul de fit score. */
public class GroqFitScoreCalculator implements FitScoreCalculatorPort {
    private static final String URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String SYSTEM_PROMPT = """
        You compute a recruitment fit score. Hard-skill assessment results are forbidden inputs.
        Weigh soft skills, CV-to-job relevance, and company context. Return JSON only:
        {"score":0,"softSkillScore":0,"cvMatchScore":0}. Every value must be 0..100.
        """;

    private final ObjectMapper objectMapper;
    private final String apiKey;
    private final String model;
    private final RestTemplate restTemplate;

    public GroqFitScoreCalculator(ObjectMapper objectMapper, String apiKey, String model,
                                  int connectTimeoutMs, int readTimeoutMs) {
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        this.model = model;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutMs);
        factory.setReadTimeout(readTimeoutMs);
        this.restTemplate = new RestTemplate(factory);
    }

    @Override
    public FitScoreResult calculate(FitScoreInputs inputs) {
        try {
            String userPrompt = objectMapper.writeValueAsString(Map.of(
                "softSkills", inputs.softSkills(),
                "cvText", inputs.cvText() == null ? "[CV_UNAVAILABLE_PROVISIONAL_STUB]" : inputs.cvText(),
                "jobDescription", String.valueOf(inputs.jobDescription()),
                "companyDescription", String.valueOf(inputs.companyDescription())));
            Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(
                    Map.of("role", "system", "content", SYSTEM_PROMPT),
                    Map.of("role", "user", "content", userPrompt)),
                "temperature", 0.1,
                "response_format", Map.of("type", "json_object"));
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);
            var response = restTemplate.postForEntity(URL, new HttpEntity<>(body, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new UpstreamServiceException("Le service de calcul de compatibilité est indisponible");
            }
            return parseResponse(response.getBody());
        } catch (HttpClientErrorException.TooManyRequests exception) {
            throw new UpstreamServiceException("Le service de calcul de compatibilité est temporairement limité", exception);
        } catch (UpstreamServiceException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new UpstreamServiceException("Le service de calcul de compatibilité est indisponible", exception);
        }
    }

    FitScoreResult parseResponse(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);
            String content = root.path("choices").path(0).path("message").path("content").asText(null);
            if (content == null) throw new IllegalArgumentException("Réponse Groq sans contenu");
            JsonNode result = objectMapper.readTree(stripFences(content));
            return new FitScoreResult(bounded(result.path("score").asInt()),
                bounded(result.path("softSkillScore").asInt()),
                bounded(result.path("cvMatchScore").asInt()));
        } catch (Exception exception) {
            throw new UpstreamServiceException("Réponse invalide du service de compatibilité", exception);
        }
    }

    private String stripFences(String content) {
        String value = content.trim();
        if (value.startsWith("```json")) value = value.substring(7);
        else if (value.startsWith("```")) value = value.substring(3);
        if (value.endsWith("```")) value = value.substring(0, value.length() - 3);
        return value.trim();
    }

    private int bounded(int value) { return Math.max(0, Math.min(100, value)); }
}
