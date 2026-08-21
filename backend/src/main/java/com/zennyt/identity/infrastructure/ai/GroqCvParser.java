package com.zennyt.identity.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.identity.application.model.CvParseData;
import com.zennyt.identity.application.port.CvParserPort;
import com.zennyt.shared.application.exception.RateLimitException;
import com.zennyt.shared.application.exception.ServiceUnavailableException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.HttpStatusCodeException;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class GroqCvParser implements CvParserPort {

    private final String apiKey;
    private final String modelName;
    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate;

    public GroqCvParser(ObjectMapper objectMapper,
                        @Value("${groq.api-key:}") String apiKey,
                        @Value("${groq.model:openai/gpt-oss-120b}") String modelName,
                        @Value("${groq.connect-timeout-ms:5000}") int connectTimeoutMs,
                        @Value("${groq.read-timeout-ms:20000}") int readTimeoutMs) {
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        this.modelName = modelName;
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(connectTimeoutMs);
        requestFactory.setReadTimeout(readTimeoutMs);
        this.restTemplate = new RestTemplate(requestFactory);
    }

    private static final String SYSTEM_PROMPT = """
        You are an expert CV parser and career assistant.
        Extract structured data from the provided CV text.
        Generate a professional 'About Me' summary based on the CV.
        
        CRITICAL RULES:
        1. Return ONLY a raw JSON object matching the exact schema requested.
        2. Do NOT wrap the JSON in Markdown code blocks (no ```json or ```).
        3. Do NOT include any explanations or extra text.
        4. If a field is missing or unclear in the CV, output null. Do NOT guess.
        5. Use exact enum values for skills: TECHNICAL or SOFT.
        6. Dates must be formatted as yyyy-MM-dd. If only a year is provided, use yyyy-01-01.
        7. Extract the exact names for positions, education, and certifications.
        8. The 'aboutMe' field should be a well-written professional summary (approx 3-5 sentences).
        9. Write the 'aboutMe' summary in the requested language.
        10. Determine if the provided document is actually a CV or Resume. Set 'isValidCv' to true if it is a CV/Resume, otherwise false. If false, you can leave other fields null.
        11. Calculate 'yearsOfExperience' by summing the duration of all relevant work experiences in years. If not explicitly stated, estimate it based on the start and end dates of the positions provided.
        
        EXPECTED JSON SCHEMA:
        {
          "isValidCv": boolean,
          "currentPosition": "string",
          "aboutMe": "string",
          "yearsOfExperience": number,
          "skills": [
            { "name": "string", "type": "TECHNICAL" | "SOFT", "level": number }
          ],
          "positions": [
            {
              "title": "string", "companyName": "string", "location": "string",
              "description": "string", "startDate": "yyyy-MM-dd", "endDate": "yyyy-MM-dd",
              "current": boolean
            }
          ],
          "education": [
            {
              "degree": "string", "school": "string", "fieldOfStudy": "string",
              "description": "string", "startDate": "yyyy-MM-dd", "endDate": "yyyy-MM-dd"
            }
          ],
          "certifications": [
            {
              "title": "string", "issuer": "string", "completionDate": "yyyy-MM-dd",
              "credentialId": "string", "credentialUrl": "string"
            }
          ]
        }
        """;

    @Override
    public CvParseData parse(String text, String language) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new ServiceUnavailableException(
                "Le service d'analyse de CV n'est pas configuré.");
        }

        String url = "https://api.groq.com/openai/v1/chat/completions";

        try {
            Map<String, Object> requestBody = Map.of(
                "model", modelName,
                "messages", List.of(
                    Map.of("role", "system", "content", SYSTEM_PROMPT),
                    Map.of("role", "user", "content", "Language required: " + language + "\n\nCV TEXT:\n" + text)
                ),
                "temperature", 0.1,
                "response_format", Map.of("type", "json_object")
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                log.error("Groq API returned error status: {}", response.getStatusCode());
                throw new ServiceUnavailableException("Échec de l'analyse du CV.");
            }

            var rootNode = objectMapper.readTree(response.getBody());
            var choices = rootNode.path("choices");
            if (choices.isMissingNode() || !choices.isArray() || choices.isEmpty()) {
                throw new ServiceUnavailableException(
                    "Réponse inattendue de Groq (aucun candidat).");
            }
            
            String jsonOutput = choices.get(0)
                .path("message")
                .path("content")
                .asText();
                
            // Groq might occasionally wrap in markdown despite json mode
            if (jsonOutput != null) {
                jsonOutput = jsonOutput.trim();
                if (jsonOutput.startsWith("```json")) {
                    jsonOutput = jsonOutput.substring(7);
                } else if (jsonOutput.startsWith("```")) {
                    jsonOutput = jsonOutput.substring(3);
                }
                if (jsonOutput.endsWith("```")) {
                    jsonOutput = jsonOutput.substring(0, jsonOutput.length() - 3);
                }
                jsonOutput = jsonOutput.trim();
            }
                
            return objectMapper.readValue(jsonOutput, CvParseData.class);

        } catch (org.springframework.web.client.HttpClientErrorException.TooManyRequests e) {
            log.warn("Groq API rate limit exceeded");
            throw new RateLimitException(
                "Quota dépassé pour l'IA Groq. Veuillez patienter une minute avant de réessayer.");
        } catch (RateLimitException | ServiceUnavailableException e) {
            throw e;
        } catch (HttpStatusCodeException e) {
            log.warn("Groq API returned status {}", e.getStatusCode());
            throw new ServiceUnavailableException("Échec de l'analyse du CV.", e);
        } catch (Exception e) {
            log.error("Error during CV parsing", e);
            throw new ServiceUnavailableException(
                "Une erreur est survenue lors de l'analyse du CV.", e);
        }
    }
}
