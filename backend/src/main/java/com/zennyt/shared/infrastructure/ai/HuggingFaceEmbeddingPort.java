package com.zennyt.shared.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.shared.application.port.EmbeddingPort;
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
 * Adaptateur HuggingFace Inference Providers (fournisseur {@code hf-inference},
 * gratuit — l'ancienne "Serverless Inference API") du calcul d'empreintes
 * (modèle multilingue léger par défaut, {@code intfloat/multilingual-e5-small}).
 *
 * <p>Endpoint confirmé début 2026 (l'ancien host direct
 * {@code api-inference.huggingface.co} a été remplacé par le routeur
 * {@code router.huggingface.co/hf-inference/...} — voir
 * huggingface.co/docs/inference-providers). Nécessite un token HuggingFace
 * "fine-grained" avec la permission "Make calls to Inference Providers"
 * (généré depuis huggingface.co/settings/tokens, pas un simple token "read").
 * La forme de la réponse varie selon le modèle (empreinte de phrase à plat,
 * ou empreintes par token à moyenner) — les deux cas sont gérés ci-dessous,
 * mais un vrai modèle n'a pas encore confirmé cette parsing en conditions
 * réelles (pas de clé configurée dans cet environnement).
 *
 * <p>Dégrade proprement vers {@code null} (pas de signal sémantique) sur
 * toute erreur — jamais d'exception qui remonterait jusqu'à l'utilisateur
 * pour une fonctionnalité purement additive.
 */
public class HuggingFaceEmbeddingPort implements EmbeddingPort {
    private static final Logger log = LoggerFactory.getLogger(HuggingFaceEmbeddingPort.class);

    private final ObjectMapper objectMapper;
    private final String apiUrl;
    private final String apiKey;
    private final RestTemplate restTemplate;

    public HuggingFaceEmbeddingPort(ObjectMapper objectMapper, String model, String apiKey,
                                    int connectTimeoutMs, int readTimeoutMs) {
        this.objectMapper = objectMapper;
        this.apiUrl = "https://router.huggingface.co/hf-inference/models/" + model + "/pipeline/feature-extraction";
        this.apiKey = apiKey;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutMs);
        factory.setReadTimeout(readTimeoutMs);
        this.restTemplate = new RestTemplate(factory);
    }

    @Override
    public float[] embed(String text) {
        if (text == null || text.isBlank()) return null;
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            // RestTemplate ajoute par défaut un Accept multi-valeurs (text/plain en tête via
            // StringHttpMessageConverter) que l'endpoint hf-inference rejette avec un 400 —
            // confirmé en direct (2026-07-27). Restreindre explicitement à application/json.
            headers.setAccept(List.of(MediaType.APPLICATION_JSON));
            headers.setBearerAuth(apiKey);
            Map<String, Object> body = Map.of("inputs", text);
            var response = restTemplate.postForEntity(apiUrl, new HttpEntity<>(body, headers), String.class);
            // Une reponse non-2xx repartait en silence : cle invalide, quota depasse ou
            // modele en cours de chargement produisaient exactement le meme resultat qu'un
            // service non configure — aucune trace, et des empreintes manquantes que rien
            // n'expliquait. Constate le 2026-08-21 sur un corpus reste sans empreinte.
            if (!response.getStatusCode().is2xxSuccessful()) {
                log.warn("[Embedding] HuggingFace a repondu {} — signal semantique indisponible",
                    response.getStatusCode());
                return null;
            }
            if (response.getBody() == null) {
                log.warn("[Embedding] HuggingFace a repondu 2xx sans corps — reponse inexploitable");
                return null;
            }
            float[] empreinte = parse(response.getBody());
            if (empreinte == null) {
                log.warn("[Embedding] Reponse HuggingFace illisible — format inattendu");
            }
            return empreinte;
        } catch (Exception exception) {
            log.warn("[Embedding] Appel HuggingFace échoué, signal sémantique désactivé pour ce texte", exception);
            return null;
        }
    }

    private float[] parse(String responseBody) throws Exception {
        JsonNode root = objectMapper.readTree(responseBody);
        if (!root.isArray() || root.isEmpty()) return null;
        // Empreinte de phrase à plat : [0.1, 0.2, ...]
        if (root.get(0).isNumber()) {
            return toFloatArray(root);
        }
        // Empreintes par token : [[0.1, 0.2, ...], [0.3, 0.4, ...], ...] -> moyenne (mean pooling)
        int dimension = root.get(0).size();
        double[] sum = new double[dimension];
        for (JsonNode token : root) {
            for (int i = 0; i < dimension; i++) {
                sum[i] += token.get(i).asDouble();
            }
        }
        float[] mean = new float[dimension];
        for (int i = 0; i < dimension; i++) {
            mean[i] = (float) (sum[i] / root.size());
        }
        return mean;
    }

    private float[] toFloatArray(JsonNode array) {
        float[] values = new float[array.size()];
        for (int i = 0; i < array.size(); i++) {
            values[i] = (float) array.get(i).asDouble();
        }
        return values;
    }
}
