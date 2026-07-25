package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Adaptateur Groq du résumé IA candidat ("Resume AI") — soft skills et hard skills. */
public class GroqResumeSummaryGenerator implements ResumeSummaryGeneratorPort {
    private static final String URL = "https://api.groq.com/openai/v1/chat/completions";

    private static final String SOFT_SKILLS_SYSTEM_PROMPT = """
        You are an occupational psychologist writing a concise soft-skills summary
        paragraph for a recruiter, based on a candidate's validated psychometric
        game results across cognitive/behavioral modules.

        CRITICAL RULES:
        1. Only reference the modules given — never invent a module or score that
           wasn't provided.
        2. Write 4-6 sentences in a professional tone, covering both strengths and
           growth areas.
        3. Return ONLY a raw JSON object: {"fr": "...", "en": "..."} — the French
           and English text must be faithful translations of the same content, not
           different summaries.
        4. Do NOT wrap the JSON in Markdown code blocks.
        """;

    private static final String HARD_SKILLS_SYSTEM_PROMPT = """
        You are an expert technical recruiter writing a concise hard-skills summary
        paragraph for a recruiter, combining a candidate's CV technical background
        with their actual test performance for a specific job.

        CRITICAL RULES:
        1. Blend CV-derived technical skills with the test score/outcome given.
        2. Write 4-6 sentences in a professional tone, covering both strengths and
           growth areas.
        3. Return ONLY a raw JSON object: {"fr": "...", "en": "..."} — the French
           and English text must be faithful translations of the same content, not
           different summaries.
        4. Do NOT wrap the JSON in Markdown code blocks.
        """;

    private final ObjectMapper objectMapper;
    private final String apiKey;
    private final String model;
    private final RestTemplate restTemplate;

    public GroqResumeSummaryGenerator(ObjectMapper objectMapper, String apiKey, String model,
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
    public BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores) {
        String userPrompt = "Module scores:\n" + moduleScores.entrySet().stream()
            .map(e -> "- " + e.getKey() + ": " + e.getValue() + "%")
            .collect(Collectors.joining("\n"));
        return call(SOFT_SKILLS_SYSTEM_PROMPT, userPrompt);
    }

    @Override
    public BilingualText generateHardSkillsSummary(String jobTitle, String cvText, int scorePercent, boolean passed) {
        String userPrompt = "Job title: " + jobTitle
            + "\nCandidate CV:\n" + (cvText == null || cvText.isBlank() ? "[no CV data available]" : cvText)
            + "\nTechnical test score: " + scorePercent + "%"
            + "\nTest outcome: " + (passed ? "passed" : "failed");
        return call(HARD_SKILLS_SYSTEM_PROMPT, userPrompt);
    }

    private BilingualText call(String systemPrompt, String userPrompt) {
        Map<String, Object> body = Map.of(
            "model", model,
            "messages", List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt)),
            "temperature", 0.3,
            "response_format", Map.of("type", "json_object"));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        try {
            var response = restTemplate.postForEntity(URL, new HttpEntity<>(body, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new UpstreamServiceException("Le service de résumé IA est indisponible");
            }
            return parseBilingualText(response.getBody());
        } catch (HttpClientErrorException.TooManyRequests exception) {
            throw new UpstreamServiceException(
                "Quota Groq dépassé — patientez une minute avant de réessayer", exception);
        } catch (UpstreamServiceException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new UpstreamServiceException("La génération du résumé IA a échoué — réessayez", exception);
        }
    }

    BilingualText parseBilingualText(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);
            JsonNode choices = root.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                throw new UpstreamServiceException("Réponse Groq inattendue (aucun choix)");
            }
            String content = stripFences(choices.get(0).path("message").path("content").asText());
            JsonNode result = objectMapper.readTree(content);
            String fr = result.path("fr").asText(null);
            String en = result.path("en").asText(null);
            if (fr == null || fr.isBlank() || en == null || en.isBlank()) {
                throw new UpstreamServiceException("Réponse IA incomplète (fr/en manquants)");
            }
            return new BilingualText(fr, en);
        } catch (UpstreamServiceException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new UpstreamServiceException("Réponse IA illisible — réessayez", exception);
        }
    }

    private static String stripFences(String content) {
        if (content == null) return "";
        String value = content.trim();
        if (value.startsWith("```json")) value = value.substring(7);
        else if (value.startsWith("```")) value = value.substring(3);
        if (value.endsWith("```")) value = value.substring(0, value.length() - 3);
        return value.trim();
    }
}
