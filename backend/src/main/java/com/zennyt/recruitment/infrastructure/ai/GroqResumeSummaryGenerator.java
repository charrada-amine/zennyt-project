package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
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

    /**
     * Horodatage à la minute, pas au jour : deux tests passés le même jour affichaient la
     * même date, le modèle n'avait aucun moyen de les ordonner et inversait la trajectoire.
     */
    private static final java.time.format.DateTimeFormatter MINUTE =
        java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm 'UTC'")
            .withZone(java.time.ZoneOffset.UTC);

    /**
     * Structure commune aux deux sections — reprise de l'exemple fourni par le métier :
     * forces, puis axes de progression, puis lecture d'ensemble. C'est ce découpage qui
     * garantit qu'une faiblesse ne peut pas être noyée : elle a son propre paragraphe.
     */
    private static final String SHARED_STRUCTURE = """

        STRUCTURE — exactly three short paragraphs, in this order:
        1. What the results establish as strengths.
        2. What the results show as areas for improvement. Never skip this paragraph;
           if the results are uniformly strong, say what would consolidate them.
        3. A closing overall reading.

        WORDING:
        - Write in your own words. Never copy a phrase from these instructions into
          the summary.
        - Do not speculate about personality, motivation, stress tolerance or private
          circumstances: a score measures a performance, not a person.
        - Return ONLY a raw JSON object: {"fr": "...", "en": "..."} — the French and
          English text must be faithful translations of the same content, not two
          different summaries. Do NOT wrap the JSON in Markdown code blocks.
        """;

    private static final String SOFT_SKILLS_SYSTEM_PROMPT = """
        You are an occupational psychologist writing a soft-skills summary of a
        candidate, based on their validated psychometric game results across
        cognitive and behavioural modules.

        - Only reference the modules given — never invent a module or a score that
          was not provided, and never infer one module from the others.
        - Describe each level qualitatively. Never quote a percentage or a raw
          score: a psychometric figure means nothing to the reader out of context,
          and invites a precision the measure does not have.
        """ + SHARED_STRUCTURE;

    private static final String HARD_SKILLS_SYSTEM_PROMPT = """
        You are an expert technical recruiter writing a hard-skills summary of a
        candidate, combining their CV background with their history of technical
        tests taken for one job position.

        ABOUT THE TEST HISTORY:
        - Each line is tagged MOST RECENT / PREVIOUS / EARLIER. These tags describe
          RECENCY ONLY. They are not attempt numbers: the line tagged EARLIER is the
          candidate's OLDEST test, not their third try. Never number the attempts.
        - The TRAJECTORY is supplied to you as an established fact. State it as
          given. Never derive a direction of your own from the list, and never write
          anything that contradicts the supplied trajectory.
        - You may cite an individual test result, since the reader can verify it.
          But never state an aggregate or overall score of your own: the figure shown
          to the reader is computed elsewhere and yours would contradict it.
        - Each test carries the seniority level of the offer it was taken for.
          Mention it only when the tests span different levels — difficulty is set by
          each recruiter and is not otherwise comparable.
        """ + SHARED_STRUCTURE;

    /**
     * Consigne de registre ajoutée au prompt de section selon le public (P5).
     *
     * <p>Elle porte sur la <b>formulation</b>, jamais sur le fond : la version candidat doit
     * mentionner les mêmes axes de progression que la version recruteur. Autoriser le modèle
     * à taire une faiblesse produirait deux évaluations divergentes du même profil, et la
     * version candidat cesserait d'être une restitution pour devenir une flatterie.
     */
    private static final String RECRUITER_TONE = """

        AUDIENCE: the recruiter, who is deciding. Objective and factual, third person
        ("the candidate"). Name each shortcoming plainly and in terms of fit for this
        kind of role. Close on the type of environment the profile suits and what
        would help it develop.
        """;

    private static final String CANDIDATE_TONE = """

        AUDIENCE: the candidate themselves, reading about their own results. Address
        them directly ("your results show..."). Keep EXACTLY the same substance,
        including every single weakness — leaving one out would misinform the person
        it concerns. Present each weakness as a skill that develops with practice and
        experience, not as a verdict. Close on their progression potential and the
        opportunities it opens. Never mention other candidates, ranking, or any
        hiring decision.
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
    public BilingualText generateSoftSkillsSummary(Map<String, Integer> moduleScores, ResumeAudience audience) {
        String userPrompt = "Module scores:\n" + moduleScores.entrySet().stream()
            .map(e -> "- " + e.getKey() + ": " + e.getValue() + "%")
            .collect(Collectors.joining("\n"));
        return call(SOFT_SKILLS_SYSTEM_PROMPT + tone(audience), userPrompt);
    }

    @Override
    public BilingualText generateHardSkillsSummary(HardSkillsContext context, ResumeAudience audience) {
        List<HardSkillTestRecap> history = context.history();
        StringBuilder lignes = new StringBuilder();
        for (int i = 0; i < history.size(); i++) {
            HardSkillTestRecap test = history.get(i);
            // Étiquette de récence en toutes lettres, jamais un numéro : numéroter les
            // lignes faisait lire « 3. » comme « troisième essai », alors que le rang 3 est
            // le test le PLUS ANCIEN. Horodatage à la minute, pas au jour : deux tests
            // passés le même jour affichaient la même date et l'ordre devenait indevinable.
            lignes.append("- ").append(recence(i)).append(" — ")
                .append(MINUTE.format(test.completedAt())).append(" — ")
                .append(test.percentage()).append("% (")
                .append(test.passed() ? "passed" : "failed")
                .append("), offer seniority ")
                .append(test.experienceLevel() == null ? "unspecified" : test.experienceLevel())
                .append('\n');
        }
        String cvText = context.cvText();
        String userPrompt = "Job position: " + context.jobPositionName()
            + "\nCandidate CV:\n" + (cvText == null || cvText.isBlank() ? "[no CV data available]" : cvText)
            + "\nTechnical tests taken for this job position:\n" + lignes
            + "\n" + context.trend().asStatement(
                history.get(0).percentage(),
                history.size() > 1 ? history.get(1).percentage() : history.get(0).percentage());
        return call(HARD_SKILLS_SYSTEM_PROMPT + tone(audience), userPrompt);
    }

    private static String tone(ResumeAudience audience) {
        return audience == ResumeAudience.CANDIDATE ? CANDIDATE_TONE : RECRUITER_TONE;
    }

    /** Étiquette de récence — jamais un rang chiffré, qui se lit comme un numéro d'essai. */
    private static String recence(int index) {
        return switch (index) {
            case 0 -> "MOST RECENT";
            case 1 -> "PREVIOUS";
            default -> "EARLIER";
        };
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
