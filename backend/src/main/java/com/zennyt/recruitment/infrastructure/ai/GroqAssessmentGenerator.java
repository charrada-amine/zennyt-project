package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Adaptateur Groq de la génération de questions d'évaluation. */
public class GroqAssessmentGenerator implements AssessmentGeneratorPort {
    private static final String URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String SYSTEM_PROMPT = """
        You are an expert technical recruiter who writes multiple-choice questions (MCQ)
        from a given source text (a job/domain description, or the content of an uploaded
        reference document such as a manual, book excerpt or existing quiz).

        CRITICAL RULES:
        1. Return ONLY a raw JSON object matching the exact schema requested.
        2. Do NOT wrap the JSON in Markdown code blocks (no ```json or ```).
        3. Each question has EXACTLY 4 options and EXACTLY one correct answer.
        4. "correctOptionIndex" is the 0-based index of the correct option (0 to 3).
        5. Options must be plausible: no joke answers, no "all of the above".
        6. Questions must be specific to the given source text.
        7. Write the questions and options in the requested language.
        8. Generate EXACTLY the requested number of questions.

        EXPECTED JSON SCHEMA:
        {
          "questions": [
            {
              "text": "string",
              "options": ["string", "string", "string", "string"],
              "correctOptionIndex": number
            }
          ]
        }
        """;

    private final ObjectMapper objectMapper;
    private final String apiKey;
    private final String model;
    private final RestTemplate restTemplate;

    public GroqAssessmentGenerator(ObjectMapper objectMapper, String apiKey, String model,
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
    public List<AssessmentQuestion> generate(GenerationSpec spec) {
        String userPrompt = "Source text:\n" + spec.sourceText()
            + "\n\nNumber of questions: " + spec.questionCount()
            + "\nLanguage: " + spec.language();

        Map<String, Object> body = Map.of(
            "model", model,
            "messages", List.of(
                Map.of("role", "system", "content", SYSTEM_PROMPT),
                Map.of("role", "user", "content", userPrompt)),
            "temperature", 0.2,
            "response_format", Map.of("type", "json_object"));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        try {
            var response = restTemplate.postForEntity(URL, new HttpEntity<>(body, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new UpstreamServiceException("Le service de génération de test est indisponible");
            }
            return parseQuestions(response.getBody(), spec.questionCount());
        } catch (HttpClientErrorException.TooManyRequests exception) {
            throw new UpstreamServiceException(
                "Quota Groq dépassé — patientez une minute avant de réessayer", exception);
        } catch (UpstreamServiceException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new UpstreamServiceException("La génération IA a échoué — réessayez", exception);
        }
    }

    /**
     * Extrait et valide les questions de la réponse chat-completions. Toute
     * sortie non conforme (mauvais nombre d'options, index hors bornes) est
     * rejetée en {@link UpstreamServiceException}.
     */
    List<AssessmentQuestion> parseQuestions(String responseBody, int expectedCount) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);
            JsonNode choices = root.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                throw new UpstreamServiceException("Réponse Groq inattendue (aucun choix)");
            }
            String content = stripFences(choices.get(0).path("message").path("content").asText());
            JsonNode questions = objectMapper.readTree(content).path("questions");
            if (!questions.isArray() || questions.isEmpty()) {
                throw new UpstreamServiceException("L'IA n'a renvoyé aucune question");
            }

            List<AssessmentQuestion> result = new ArrayList<>();
            for (JsonNode q : questions) {
                List<String> options = new ArrayList<>();
                q.path("options").forEach(o -> options.add(o.asText()));
                try {
                    result.add(new AssessmentQuestion(
                        q.path("text").asText(), options, q.path("correctOptionIndex").asInt(-1)));
                } catch (IllegalArgumentException invalid) {
                    throw new UpstreamServiceException(
                        "Question IA invalide (" + invalid.getMessage() + ") — réessayez");
                }
            }
            return result;
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
