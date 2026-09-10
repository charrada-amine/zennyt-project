package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.catalog.EmotionalRadarSceneCatalog;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.SceneMediaType;
import com.zennyt.games.infrastructure.persistence.EmotionalRadarSceneEntity;
import com.zennyt.games.infrastructure.persistence.JpaEmotionalRadarSceneRepository;
import org.springframework.stereotype.Component;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.Map;
import java.util.LinkedHashMap;

/**
 * Catalogue de scènes adossé à la base ({@code V25}).
 *
 * <p>Contrairement à {@code EmptyDecisionScenarioCatalog}, cette implémentation
 * n'est pas vide : trois scènes rédigées sont livrées par la migration. Les douze
 * scènes restantes ne sont pas inventées — elles seront simplement insérées quand
 * le psychologue les fournira, sans aucun changement de code.
 */
@Component
public class DatabaseEmotionalRadarSceneCatalog implements EmotionalRadarSceneCatalog {

    private final JpaEmotionalRadarSceneRepository repository;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public DatabaseEmotionalRadarSceneCatalog(JpaEmotionalRadarSceneRepository repository,
                                              JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.repository = repository;
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    @Override
    public List<EmotionalRadarScene> scenes() {
        return repository.findByActiveTrueOrderBySceneOrderAsc().stream()
            .map(EmotionalRadarSceneEntity::toDomain)
            .toList();
    }

    @Override
    public List<EmotionalRadarScene> scenes(UUID bankId) {
        if (bankId == null) return scenes();
        List<UUID> ids = jdbc.query("""
            SELECT content_id FROM games.admin_bank_items
             WHERE bank_id=? ORDER BY position
            """, (rs, row) -> rs.getObject("content_id", UUID.class), bankId);
        Map<UUID, EmotionalRadarSceneEntity> byId = new LinkedHashMap<>();
        repository.findAllById(ids).stream().filter(EmotionalRadarSceneEntity::isActive)
            .forEach(scene -> byId.put(scene.getId(), scene));
        Map<UUID, EmotionalRadarScene> managed = new LinkedHashMap<>();
        if (byId.size() != ids.size()) {
            jdbc.query("""
                SELECT id, prompt, payload::text FROM games.admin_questions
                 WHERE status='PUBLISHED' AND content_type='EMOTIONAL_RADAR_SCENE'
                """, rs -> {
                    UUID id = rs.getObject("id", UUID.class);
                    if (ids.contains(id)) {
                        managed.put(id, managedScene(id, rs.getString("prompt"),
                            rs.getString("payload")));
                    }
                });
        }
        List<EmotionalRadarScene> result = ids.stream().map(id -> {
            EmotionalRadarSceneEntity scene = byId.get(id);
            return scene == null ? managed.get(id) : scene.toDomain();
        }).filter(java.util.Objects::nonNull).toList();
        if (result.size() != ids.size()) {
            throw new IllegalStateException("La banque Emotional Radar contient une scène inactive");
        }
        return result;
    }

    private EmotionalRadarScene managedScene(UUID id, String prompt, String payloadJson) {
        try {
            JsonNode payload = objectMapper.readTree(payloadJson);
            return new EmotionalRadarScene(id, payload.path("sceneOrder").asInt(1),
                SceneMediaType.valueOf(requiredText(payload, "mediaType")), prompt,
                requiredText(payload, "instructionText"), nullableText(payload, "mediaUrl"),
                null, nullableText(payload, "altText"), nullableText(payload, "transcript"),
                BasicEmotion.valueOf(requiredText(payload, "expectedEmotion")),
                requiredText(payload, "expectedNuance"), payload.path("expectedIntensity").asInt(),
                requiredText(payload, "explanation"));
        } catch (java.io.IOException exception) {
            throw new IllegalStateException("Scène Emotional Radar administrée invalide", exception);
        }
    }

    private static String requiredText(JsonNode node, String key) {
        String value = node.path(key).asText("");
        if (value.isBlank()) throw new IllegalStateException("Clé Emotional Radar requise : " + key);
        return value;
    }

    private static String nullableText(JsonNode node, String key) {
        return node.path(key).isTextual() ? node.path(key).asText() : null;
    }

    @Override
    public Optional<EmotionalRadarScene> findById(UUID sceneId) {
        return repository.findById(sceneId)
            .filter(EmotionalRadarSceneEntity::isActive)
            .map(EmotionalRadarSceneEntity::toDomain);
    }
}
