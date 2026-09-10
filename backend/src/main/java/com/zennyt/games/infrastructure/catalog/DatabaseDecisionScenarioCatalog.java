package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.vo.OptionQuality;
import com.zennyt.games.infrastructure.persistence.DecisionScenarioEntity;
import com.zennyt.games.infrastructure.persistence.JpaDecisionScenarioRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Catalogue « Je Décide » adossé à la base (V59) — implémentation vivante des deux
 * ports : {@link DecisionScenarioCatalog} pour la notation,
 * {@link DecisionFormCatalog} pour la présentation.
 *
 * <p>Remplace {@code JsonDecisionScenarioCatalog}, qui lisait la banque en ressource.
 * Le passage en base ne change <b>aucun score</b> : les mêmes 120 items, les mêmes
 * qualités d'option. Le JSON reste dans le dépôt comme source du seed Flyway.
 *
 * <p>Le contenu servi passe par le port de présentation, jamais par le port de
 * notation : ce dernier ne connaît que les qualités et n'a rien à publier.
 */
@Component
public class DatabaseDecisionScenarioCatalog
    implements DecisionScenarioCatalog, DecisionFormCatalog {

    private final JpaDecisionScenarioRepository repository;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public DatabaseDecisionScenarioCatalog(JpaDecisionScenarioRepository repository,
                                           JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.repository = repository;
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    // ── Port de notation ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Optional<Item> item(String itemId) {
        return repository.findByItemId(itemId).map(DatabaseDecisionScenarioCatalog::toScoringItem)
            .or(() -> managedItem(itemId, null));
    }

    @Override
    public Optional<Item> item(String itemId, UUID bankId) {
        Optional<Item> managed = managedItem(itemId, bankId);
        return managed.isPresent() ? managed : repository.findByItemId(itemId)
            .map(DatabaseDecisionScenarioCatalog::toScoringItem);
    }

    private Optional<Item> managedItem(String itemId, UUID bankId) {
        String bankFilter = bankId == null ? "" : """
             AND EXISTS (SELECT 1 FROM games.admin_bank_items item
                          WHERE item.bank_id=? AND item.content_id=q.id)
            """;
        Object[] arguments = bankId == null ? new Object[]{itemId} : new Object[]{itemId, bankId};
        return jdbc.query("""
            SELECT external_code, payload::text FROM games.admin_questions q
             WHERE content_type='DECISION_SCENARIO' AND status='PUBLISHED'
               AND external_code=?
            """ + bankFilter, (rs, row) -> managedScoringItem(
                rs.getString("external_code"), rs.getString("payload")), arguments)
            .stream().findFirst();
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isEmpty() {
        return repository.count() == 0;
    }

    private static Item toScoringItem(DecisionScenarioEntity entity) {
        Map<String, OptionQuality> qualities = new LinkedHashMap<>();
        entity.getOptions().forEach(o -> qualities.put(o.getOptionId(), o.getQuality()));
        return new Item(entity.getItemId(), entity.getDimension(), entity.getFormat(),
            entity.isProvisionalScoring(), qualities);
    }

    // ── Port de présentation ────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<Content> form(String formCode) {
        List<DecisionScenarioEntity> items = repository.findFormItems(formCode);
        return toContents(items);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Content> bank(UUID bankId, String fallbackFormCode) {
        if (bankId == null) return form(fallbackFormCode);
        List<UUID> ids = jdbc.query("""
            SELECT content_id FROM games.admin_bank_items
             WHERE bank_id=? ORDER BY position
            """, (rs, row) -> rs.getObject("content_id", UUID.class), bankId);
        Map<UUID, DecisionScenarioEntity> byId = new LinkedHashMap<>();
        repository.findAllById(ids).forEach(item -> byId.put(item.getId(), item));
        Map<UUID, Content> managed = new LinkedHashMap<>();
        if (byId.size() != ids.size()) {
            jdbc.query("""
                SELECT id, external_code, prompt, payload::text
                  FROM games.admin_questions
                 WHERE status='PUBLISHED' AND content_type='DECISION_SCENARIO'
                """, rs -> {
                    UUID id = rs.getObject("id", UUID.class);
                    if (ids.contains(id)) {
                        managed.put(id, managedContent(rs.getString("external_code"),
                            rs.getString("prompt"), rs.getString("payload")));
                    }
                });
        }
        List<Content> result = ids.stream().map(id -> {
            DecisionScenarioEntity item = byId.get(id);
            return item == null ? managed.get(id) : toContents(List.of(item)).getFirst();
        }).filter(java.util.Objects::nonNull).toList();
        if (result.size() != ids.size()) {
            throw new IllegalStateException("La banque Je Décide contient un item non autoritatif");
        }
        return result;
    }

    private List<Content> toContents(List<DecisionScenarioEntity> items) {
        if (items.isEmpty()) {
            return List.of();
        }
        // Les items DT n'ont pas de vignette propre : ils réutilisent celle de leur
        // homologue II (DT-7 → II-7). On résout la référence ici, pour que le client
        // reçoive un item auto-suffisant et n'ait aucune jointure à refaire.
        Set<String> referenced = items.stream()
            .map(DecisionScenarioEntity::getVignetteRef)
            .filter(java.util.Objects::nonNull)
            .collect(Collectors.toSet());
        Map<String, String> vignetteByItemId = referenced.isEmpty()
            ? Map.of()
            : repository.findByItemIdIn(referenced).stream()
                .collect(Collectors.toMap(
                    DecisionScenarioEntity::getItemId, DecisionScenarioEntity::getVignette));

        return items.stream().map(e -> toContent(e, vignetteByItemId)).toList();
    }

    private static Content toContent(DecisionScenarioEntity e, Map<String, String> vignettes) {
        String vignette = e.getVignette() != null
            ? e.getVignette()
            : vignettes.get(e.getVignetteRef());
        if (vignette == null) {
            throw new IllegalStateException(
                "Vignette introuvable pour l'item " + e.getItemId()
                    + " (référence : " + e.getVignetteRef() + ")");
        }
        return new Content(
            e.getItemId(),
            e.getDimension(),
            e.getFormat(),
            e.getPairId(),
            vignette,
            e.getTask(),
            e.isProvisionalScoring(),
            e.getOptions().stream()
                .map(o -> new Content.Option(o.getOptionId(), o.getLabel(), o.getQuality()))
                .toList());
    }

    private Item managedScoringItem(String itemId, String payloadJson) {
        JsonNode payload = json(payloadJson);
        Map<String, OptionQuality> qualities = new LinkedHashMap<>();
        payload.path("options").forEach(option -> qualities.put(
            requiredText(option, "optionId"),
            OptionQuality.valueOf(requiredText(option, "quality"))));
        return new Item(itemId,
            com.zennyt.games.domain.vo.DecisionDimension.valueOf(requiredText(payload, "dimension")),
            com.zennyt.games.domain.vo.DecisionItemFormat.valueOf(requiredText(payload, "format")),
            payload.path("provisionalScoring").asBoolean(false), qualities);
    }

    private Content managedContent(String itemId, String prompt, String payloadJson) {
        JsonNode payload = json(payloadJson);
        String vignette = payload.path("vignette").isTextual()
            ? payload.path("vignette").asText() : prompt;
        List<Content.Option> options = new java.util.ArrayList<>();
        payload.path("options").forEach(option -> options.add(new Content.Option(
            requiredText(option, "optionId"), requiredText(option, "label"),
            OptionQuality.valueOf(requiredText(option, "quality")))));
        return new Content(itemId,
            com.zennyt.games.domain.vo.DecisionDimension.valueOf(requiredText(payload, "dimension")),
            com.zennyt.games.domain.vo.DecisionItemFormat.valueOf(requiredText(payload, "format")),
            nullableText(payload, "pairId"), vignette, requiredText(payload, "task"),
            payload.path("provisionalScoring").asBoolean(false), options);
    }

    private JsonNode json(String value) {
        try {
            return objectMapper.readTree(value);
        } catch (java.io.IOException exception) {
            throw new IllegalStateException("Question Je Décide administrée invalide", exception);
        }
    }

    private static String requiredText(JsonNode node, String key) {
        String value = node.path(key).asText("");
        if (value.isBlank()) throw new IllegalStateException("Clé Je Décide requise : " + key);
        return value;
    }

    private static String nullableText(JsonNode node, String key) {
        return node.path(key).isTextual() ? node.path(key).asText() : null;
    }
}
