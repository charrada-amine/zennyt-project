package com.zennyt.engagement.infrastructure.help;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.engagement.application.port.HelpAnswerPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * Rédige la réponse d'aide avec Groq, à partir des extraits retenus.
 *
 * <p><b>La consigne est une contrainte, pas une suggestion.</b> Le modèle reformule les
 * extraits ; il n'a pas le droit d'ajouter un fait. C'est nécessaire mais pas suffisant :
 * un modèle peut désobéir, et c'est pourquoi le garde-fou principal est ailleurs — la
 * recherche ne remonte rien quand la question sort du corpus, et l'appelant n'invoque
 * alors jamais ce service.
 */
public class GroqHelpAnswerPort implements HelpAnswerPort {

    private static final Logger log = LoggerFactory.getLogger(GroqHelpAnswerPort.class);
    private static final String URL = "https://api.groq.com/openai/v1/chat/completions";

    private static final String CONSIGNE = """
        Tu es l'assistant du centre d'aide de Zennyt, une plateforme de recrutement.

        Règles absolues :
        - Réponds UNIQUEMENT à partir des extraits de documentation fournis.
        - N'ajoute aucun fait, aucun chiffre, aucune procédure qui n'y figure pas.
        - Si les extraits ne suffisent pas à répondre, dis-le franchement et propose de
          transmettre la question à une personne. N'invente jamais pour combler.
        - Ne promets aucune action : tu lis la documentation, tu ne modifies aucun compte.

        Style : deux à quatre phrases, en français, sans liste à puces, sans formule
        d'accueil ni de politesse finale. Va droit au fait, comme quelqu'un qui connaît le
        produit et respecte le temps de son interlocuteur.
        """;

    private final ObjectMapper objectMapper;
    private final String apiKey;
    private final String model;
    private final RestTemplate restTemplate;

    public GroqHelpAnswerPort(ObjectMapper objectMapper, String apiKey, String model,
                              int connectTimeoutMs, int readTimeoutMs) {
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        this.model = model;
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutMs);
        factory.setReadTimeout(readTimeoutMs);
        this.restTemplate = new RestTemplate(factory);
    }

    @Override
    public String redigerReponse(String question, List<String> extraits, boolean tutoyer) {
        if (extraits == null || extraits.isEmpty()) return null;

        StringBuilder demande = new StringBuilder("Question de l'utilisateur :\n")
            .append(question)
            .append("\n\nExtraits de la documentation :\n");
        for (int i = 0; i < extraits.size(); i++) {
            demande.append("\n--- Extrait ").append(i + 1).append(" ---\n").append(extraits.get(i));
        }
        if (tutoyer) demande.append("\n\nEmploie le tutoiement.");

        Map<String, Object> body = Map.of(
            "model", model,
            "messages", List.of(
                Map.of("role", "system", "content", CONSIGNE),
                Map.of("role", "user", "content", demande.toString())),
            // Température basse : on veut une reformulation fidèle, pas de la variété.
            "temperature", 0.2);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        try {
            var response = restTemplate.postForEntity(URL, new HttpEntity<>(body, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                log.warn("[Aide] Groq a répondu {} — l'extrait sera servi tel quel",
                    response.getStatusCode());
                return null;
            }
            JsonNode racine = objectMapper.readTree(response.getBody());
            JsonNode contenu = racine.path("choices").path(0).path("message").path("content");
            if (contenu.isMissingNode() || contenu.asText().isBlank()) {
                log.warn("[Aide] Réponse Groq vide — l'extrait sera servi tel quel");
                return null;
            }
            return contenu.asText().trim();
        } catch (Exception exception) {
            log.warn("[Aide] Appel Groq échoué — l'extrait sera servi tel quel", exception);
            return null;
        }
    }
}
