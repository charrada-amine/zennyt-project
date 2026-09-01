package com.zennyt.games.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.model.AdminModels.*;
import com.zennyt.games.domain.model.GameRuntimeSnapshot;
import com.zennyt.games.domain.repository.GameAdminRepository;
import com.zennyt.games.domain.vo.GameType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@Repository
public class JdbcGameAdminRepository implements GameAdminRepository {
    private static final String QUESTION_SELECT = """
        SELECT * FROM (
          SELECT s.id, s.item_id AS external_code, 'DECISION_SCENARIO'::varchar AS content_type,
                 concat_ws(E'\n', s.vignette, s.task) AS prompt,
                 jsonb_build_object(
                    'dimension', s.dimension,
                    'format', s.format,
                    'pairId', s.pair_id,
                    'vignette', s.vignette,
                    'vignetteRef', s.vignette_ref,
                    'task', s.task,
                    'provisionalScoring', s.provisional_scoring,
                    'options', (SELECT jsonb_agg(jsonb_build_object(
                        'optionId', o.option_id,
                        'label', o.label,
                        'quality', o.quality
                    ) ORDER BY o.position)
                    FROM games.decision_scenario_options o WHERE o.scenario_id=s.id)
                 )::text AS payload_json,
                 'PUBLISHED'::varchar AS status, 'Je Décide - Forme A'::varchar AS bank_name,
                 NULL::uuid AS source_id, false AS managed, s.updated_at
            FROM games.decision_scenarios s
          UNION ALL
          SELECT s.id, concat('ER-', lpad(s.scene_order::text, 3, '0')),
                 'EMOTIONAL_RADAR_SCENE'::varchar, s.prompt_text,
                 jsonb_build_object(
                    'sceneOrder', s.scene_order,
                    'instructionText', s.instruction_text,
                    'mediaType', s.media_type,
                    'mediaUrl', s.media_url,
                    'altText', s.alt_text,
                    'transcript', s.transcript,
                    'explanation', s.explanation,
                    'expectedEmotion', s.expected_emotion,
                    'expectedNuance', s.expected_nuance,
                    'expectedIntensity', s.expected_intensity
                 )::text,
                 CASE WHEN s.active THEN 'PUBLISHED' ELSE 'ARCHIVED' END::varchar,
                 'Radar émotionnel - Core'::varchar, NULL::uuid, false,
                 (SELECT updated_at FROM games.admin_banks
                   WHERE id='81000000-0000-0000-0000-000000000002')
            FROM games.emotional_radar_scenes s
          UNION ALL
          SELECT q.id, q.external_code, q.content_type, q.prompt,
                 q.payload::text, q.status,
                 (SELECT b.name FROM games.admin_bank_items bi
                    JOIN games.admin_banks b ON b.id=bi.bank_id
                   WHERE bi.content_id=q.id ORDER BY b.updated_at DESC LIMIT 1),
                 q.source_id, true, q.updated_at
            FROM games.admin_questions q
        ) content
        """;

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public JdbcGameAdminRepository(JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    @Override
    public GameRuntimeSnapshot runtimeSnapshot(GameType gameType) {
        List<Configuration> published = jdbc.query("""
            SELECT * FROM games.admin_configurations
             WHERE game_type=? AND status='PUBLISHED'
             ORDER BY configuration_kind
            """, (rs, row) -> configuration(rs, row), gameType.name());
        Configuration settings = published.stream()
            .filter(value -> value.kind() == ConfigurationKind.SETTINGS).findFirst().orElse(null);
        Configuration modifiers = published.stream()
            .filter(value -> value.kind() == ConfigurationKind.MODIFIERS).findFirst().orElse(null);
        Bank bank = selectPublishedBank(gameType);
        return new GameRuntimeSnapshot(
            bank == null ? null : bank.id(),
            bank == null ? null : bank.code(),
            bank == null ? null : bank.version(),
            bank == null ? null : bank.contentType().name(),
            settings == null ? null : settings.version(),
            modifiers == null ? null : modifiers.version(),
            settings == null ? Map.of() : jsonMap(settings.valuesJson()),
            modifiers == null ? Map.of() : jsonMap(modifiers.valuesJson()));
    }

    private Bank selectPublishedBank(GameType gameType) {
        ContentType type = switch (gameType) {
            case DECISION -> ContentType.DECISION_SCENARIO;
            case EMOTIONAL_REGULATION -> ContentType.EMOTIONAL_RADAR_SCENE;
            default -> null;
        };
        if (type == null) return null;
        List<Bank> candidates = banks().stream()
            .filter(bank -> bank.status() == Status.PUBLISHED && bank.contentType() == type)
            .toList();
        if (candidates.isEmpty()) return null;
        int totalWeight = candidates.stream().mapToInt(Bank::rotationWeight).sum();
        if (totalWeight <= 0) return candidates.getFirst();
        int draw = ThreadLocalRandom.current().nextInt(totalWeight);
        for (Bank candidate : candidates) {
            draw -= candidate.rotationWeight();
            if (draw < 0) return candidate;
        }
        return candidates.getLast();
    }

    @Override
    public Overview overview() {
        Long questions = jdbc.queryForObject("""
            SELECT (SELECT count(*) FROM games.decision_scenarios)
                 + (SELECT count(*) FROM games.emotional_radar_scenes)
                 + (SELECT count(*) FROM games.admin_questions)
            """, Long.class);
        Long published = jdbc.queryForObject("SELECT count(*) FROM games.admin_banks WHERE status='PUBLISHED'", Long.class);
        Long drafts = jdbc.queryForObject("""
            SELECT (SELECT count(*) FROM games.admin_questions WHERE status='DRAFT')
                 + (SELECT count(*) FROM games.admin_banks WHERE status='DRAFT')
                 + (SELECT count(*) FROM games.admin_configurations WHERE status='DRAFT')
                 + (SELECT count(*) FROM games.admin_assets WHERE status='DRAFT')
            """, Long.class);
        Long assets = jdbc.queryForObject("SELECT count(*) FROM games.admin_assets", Long.class);
        return new Overview(orZero(questions), orZero(published), orZero(drafts), orZero(assets));
    }

    @Override
    public List<Question> questions(ContentType type, String query) {
        String sql = QUESTION_SELECT + """
            WHERE (CAST(? AS varchar) IS NULL OR content_type = CAST(? AS varchar))
              AND (CAST(? AS varchar) = '' OR lower(external_code || ' ' || prompt)
                   LIKE lower('%' || CAST(? AS varchar) || '%'))
            ORDER BY updated_at DESC, external_code
            """;
        String typeName = type == null ? null : type.name();
        return jdbc.query(sql, this::question, typeName, typeName, query, query);
    }

    @Override
    public Optional<Question> findQuestion(UUID questionId) {
        return jdbc.query(QUESTION_SELECT + " WHERE id=? ORDER BY managed DESC LIMIT 1",
            this::question, questionId).stream().findFirst();
    }

    @Override
    public Question saveQuestion(Question question, UUID actorId) {
        jdbc.update("""
            INSERT INTO games.admin_questions
              (id, external_code, content_type, prompt, payload, status, source_id,
               created_by, created_at, updated_at)
            VALUES (?, ?, ?, ?, CAST(? AS jsonb), ?, ?, ?, ?, ?)
            """, question.id(), question.externalCode(), question.contentType().name(), question.prompt(),
            question.payloadJson(), question.status().name(), question.sourceId(), actorId,
            Timestamp.from(question.updatedAt()), Timestamp.from(question.updatedAt()));
        audit("QUESTION_CREATED", "QUESTION", question.id(), actorId);
        return question;
    }

    @Override
    public Question updateQuestion(Question question, UUID actorId) {
        int updated = jdbc.update("""
            UPDATE games.admin_questions
               SET external_code=?, content_type=?, prompt=?, payload=CAST(? AS jsonb), updated_at=now()
             WHERE id=? AND status='DRAFT'
            """, question.externalCode(), question.contentType().name(), question.prompt(),
            question.payloadJson(), question.id());
        if (updated != 1) throw new IllegalStateException("Seul un brouillon administré peut être modifié");
        audit("QUESTION_UPDATED", "QUESTION", question.id(), actorId);
        return findQuestion(question.id()).orElseThrow();
    }

    @Override
    public Question changeQuestionStatus(UUID questionId, Status status, UUID actorId) {
        Question selected = findQuestion(questionId)
            .filter(Question::managed)
            .orElseThrow(() -> new IllegalArgumentException("Question administrée introuvable"));
        if (status == Status.PUBLISHED) {
            jdbc.update("""
                UPDATE games.admin_questions SET status='ARCHIVED', updated_at=now()
                 WHERE content_type=? AND external_code=? AND status='PUBLISHED' AND id<>?
                """, selected.contentType().name(), selected.externalCode(), questionId);
        }
        int updated = jdbc.update("UPDATE games.admin_questions SET status=?, updated_at=now() WHERE id=?",
            status.name(), questionId);
        if (updated != 1) throw new IllegalArgumentException("Question administrée introuvable");
        audit("QUESTION_" + status.name(), "QUESTION", questionId, actorId);
        return findQuestion(questionId).orElseThrow();
    }

    @Override
    public void deleteQuestionDraft(UUID questionId, UUID actorId) {
        Integer used = jdbc.queryForObject(
            "SELECT count(*) FROM games.admin_bank_items WHERE content_id=?", Integer.class, questionId);
        if (used != null && used > 0) {
            throw new IllegalStateException("Retirez la question de ses banques avant suppression");
        }
        int deleted = jdbc.update("DELETE FROM games.admin_questions WHERE id=? AND status='DRAFT'", questionId);
        if (deleted != 1) throw new IllegalStateException("Seul un brouillon administré peut être supprimé");
        audit("QUESTION_DELETED", "QUESTION", questionId, actorId);
    }

    @Override
    public List<Bank> banks() {
        return jdbc.query("""
            SELECT b.*, count(i.content_id) AS item_count
              FROM games.admin_banks b
              LEFT JOIN games.admin_bank_items i ON i.bank_id=b.id
             GROUP BY b.id ORDER BY b.updated_at DESC
            """, this::bank);
    }

    @Override
    public Bank createBank(Bank bank, UUID actorId, UUID sourceBankId) {
        Integer version = jdbc.queryForObject("SELECT COALESCE(max(version),0)+1 FROM games.admin_banks WHERE code=?", Integer.class, bank.code());
        int nextVersion = version == null ? 1 : version;
        jdbc.update("""
            INSERT INTO games.admin_banks
              (id, code, name, content_type, version, rotation_weight, status, created_by, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, 'DRAFT', ?, ?, ?)
            """, bank.id(), bank.code(), bank.name(), bank.contentType().name(), nextVersion,
            bank.rotationWeight(), actorId, Timestamp.from(bank.updatedAt()), Timestamp.from(bank.updatedAt()));
        if (sourceBankId != null) {
            Integer matchingType = jdbc.queryForObject("""
                SELECT count(*) FROM games.admin_banks
                 WHERE id=? AND content_type=?
                """, Integer.class, sourceBankId, bank.contentType().name());
            if (matchingType == null || matchingType != 1) {
                throw new IllegalArgumentException("La banque source est introuvable ou incompatible");
            }
            jdbc.update("""
                INSERT INTO games.admin_bank_items (bank_id, content_id, position)
                SELECT ?, content_id, position FROM games.admin_bank_items WHERE bank_id=?
                """, bank.id(), sourceBankId);
        }
        audit("BANK_CREATED", "BANK", bank.id(), actorId);
        return findBank(bank.id()).orElseThrow();
    }

    @Override
    public Optional<Bank> findBank(UUID bankId) {
        List<Bank> rows = jdbc.query("""
            SELECT b.*, count(i.content_id) AS item_count
              FROM games.admin_banks b LEFT JOIN games.admin_bank_items i ON i.bank_id=b.id
             WHERE b.id=? GROUP BY b.id
            """, this::bank, bankId);
        return rows.stream().findFirst();
    }

    @Override
    public Bank updateBank(UUID bankId, String name, int rotationWeight, UUID actorId) {
        int updated = jdbc.update("""
            UPDATE games.admin_banks SET name=?, rotation_weight=?, updated_at=now()
             WHERE id=? AND status='DRAFT'
            """, name, rotationWeight, bankId);
        if (updated != 1) throw new IllegalStateException("Seul un brouillon de banque peut être modifié");
        audit("BANK_UPDATED", "BANK", bankId, actorId);
        return findBank(bankId).orElseThrow();
    }

    @Override
    public List<UUID> bankItems(UUID bankId) {
        if (findBank(bankId).isEmpty()) throw new IllegalArgumentException("Banque introuvable");
        return jdbc.query("SELECT content_id FROM games.admin_bank_items WHERE bank_id=? ORDER BY position",
            (rs, row) -> uuid(rs, "content_id"), bankId);
    }

    @Override
    public Bank replaceBankItems(UUID bankId, List<UUID> questionIds, UUID actorId) {
        Bank bank = findBank(bankId)
            .orElseThrow(() -> new IllegalArgumentException("Banque introuvable"));
        if (bank.status() != Status.DRAFT) {
            throw new IllegalStateException("Seule la composition d'un brouillon peut être modifiée");
        }
        if (questionIds.stream().distinct().count() != questionIds.size()) {
            throw new IllegalArgumentException("Une question ne peut apparaître qu'une fois dans une banque");
        }
        for (UUID questionId : questionIds) {
            Question question = findQuestion(questionId)
                .orElseThrow(() -> new IllegalArgumentException("Question introuvable : " + questionId));
            if (question.contentType() != bank.contentType() || question.status() == Status.ARCHIVED) {
                throw new IllegalArgumentException("Question incompatible ou archivée : " + questionId);
            }
        }
        jdbc.update("DELETE FROM games.admin_bank_items WHERE bank_id=?", bankId);
        for (int index = 0; index < questionIds.size(); index++) {
            jdbc.update("INSERT INTO games.admin_bank_items (bank_id, content_id, position) VALUES (?, ?, ?)",
                bankId, questionIds.get(index), index + 1);
        }
        jdbc.update("UPDATE games.admin_banks SET updated_at=now() WHERE id=?", bankId);
        audit("BANK_ITEMS_REPLACED", "BANK", bankId, actorId,
            "{\"itemCount\":" + questionIds.size() + "}");
        return findBank(bankId).orElseThrow();
    }

    @Override
    public Bank publishBank(UUID bankId, UUID actorId) {
        Bank selected = findBank(bankId).orElseThrow();
        validateRuntimeBank(selected);
        jdbc.update("UPDATE games.admin_banks SET status='ARCHIVED', updated_at=now() WHERE code=? AND status='PUBLISHED' AND id<>?", selected.code(), bankId);
        int updated = jdbc.update("UPDATE games.admin_banks SET status='PUBLISHED', published_at=now(), updated_at=now() WHERE id=? AND status='DRAFT'", bankId);
        if (updated != 1) throw new IllegalStateException("Seule une banque en brouillon peut être publiée");
        audit("BANK_PUBLISHED", "BANK", bankId, actorId);
        return findBank(bankId).orElseThrow();
    }

    private void validateRuntimeBank(Bank bank) {
        String eligibility = bank.contentType() == ContentType.DECISION_SCENARIO ? """
            SELECT count(*) FROM games.admin_bank_items items
              LEFT JOIN games.decision_scenarios content ON content.id=items.content_id
              LEFT JOIN games.admin_questions managed ON managed.id=items.content_id
             WHERE items.bank_id=? AND (
               content.id IS NOT NULL OR (
                 managed.status='PUBLISHED' AND managed.content_type='DECISION_SCENARIO'
                 AND jsonb_exists_all(managed.payload, ARRAY['dimension','format','task','options'])
                 AND managed.payload->>'dimension' IN ('II','ER','DT','CS','RE')
                 AND managed.payload->>'format' IN ('STANDARD','TEMPORAL_DECISION','COHERENCE_PAIR')
                 AND jsonb_array_length(managed.payload->'options') >= 2
                 AND NOT EXISTS (
                   SELECT 1 FROM jsonb_array_elements(managed.payload->'options') option
                    WHERE NOT jsonb_exists_all(option, ARRAY['optionId','label','quality'])
                       OR option->>'quality' NOT IN
                         ('OPTIMAL','SATISFACTORY','PARTIAL','DEFICIENT'))))
            """ : """
            SELECT count(*) FROM games.admin_bank_items items
              LEFT JOIN games.emotional_radar_scenes content
                ON content.id=items.content_id AND content.active=TRUE
              LEFT JOIN games.admin_questions managed ON managed.id=items.content_id
             WHERE items.bank_id=? AND (
               content.id IS NOT NULL OR (
                 managed.status='PUBLISHED' AND managed.content_type='EMOTIONAL_RADAR_SCENE'
                 AND jsonb_exists_all(managed.payload, ARRAY['sceneOrder','mediaType','instructionText',
                   'expectedEmotion','expectedNuance','expectedIntensity','explanation'])
                 AND managed.payload->>'mediaType' IN ('DIALOGUE','TEXT','IMAGE','VIDEO')
                 AND managed.payload->>'expectedEmotion' IN
                   ('JOY','SADNESS','ANGER','FEAR','DISGUST','SURPRISE')
                 AND managed.payload->>'expectedIntensity' IN ('1','2','3','4','5')))
            """;
        Integer eligible = jdbc.queryForObject(eligibility, Integer.class, bank.id());
        if (eligible == null || eligible != bank.itemCount()) {
            throw new IllegalStateException(
                "La banque contient une question non publiée ou un payload runtime incomplet");
        }
        if (bank.contentType() == ContentType.DECISION_SCENARIO
                && bank.itemCount() != com.zennyt.games.domain.config.DecisionConfig.TOTAL_ITEMS) {
            throw new IllegalStateException("Une forme Je Décide doit contenir exactement 30 items");
        }
    }

    @Override
    public Bank archiveBank(UUID bankId, UUID actorId) {
        int updated = jdbc.update("UPDATE games.admin_banks SET status='ARCHIVED', updated_at=now() WHERE id=? AND status<>'ARCHIVED'", bankId);
        if (updated != 1) throw new IllegalStateException("La banque est introuvable ou déjà archivée");
        audit("BANK_ARCHIVED", "BANK", bankId, actorId);
        return findBank(bankId).orElseThrow();
    }

    @Override
    public void deleteBankDraft(UUID bankId, UUID actorId) {
        int deleted = jdbc.update("DELETE FROM games.admin_banks WHERE id=? AND status='DRAFT'", bankId);
        if (deleted != 1) throw new IllegalStateException("Seul un brouillon de banque peut être supprimé");
        audit("BANK_DELETED", "BANK", bankId, actorId);
    }

    @Override
    public List<Configuration> configurations(ConfigurationKind kind) {
        if (kind == null) {
            return jdbc.query("SELECT * FROM games.admin_configurations ORDER BY updated_at DESC",
                (rs, row) -> configuration(rs, row));
        }
        return jdbc.query("SELECT * FROM games.admin_configurations WHERE configuration_kind=? ORDER BY updated_at DESC",
            (rs, row) -> configuration(rs, row), kind.name());
    }

    @Override
    public Optional<Configuration> findConfiguration(UUID configurationId) {
        return jdbc.query("SELECT * FROM games.admin_configurations WHERE id=?",
            (rs, row) -> configuration(rs, row), configurationId).stream().findFirst();
    }

    @Override
    public Configuration createConfiguration(Configuration configuration, UUID actorId) {
        Integer version = jdbc.queryForObject("SELECT COALESCE(max(version),0)+1 FROM games.admin_configurations WHERE game_type=? AND configuration_kind=?", Integer.class, configuration.gameType(), configuration.kind().name());
        int nextVersion = version == null ? 1 : version;
        jdbc.update("""
            INSERT INTO games.admin_configurations
              (id, game_type, configuration_kind, version, values_json, status, created_by, created_at, updated_at)
            VALUES (?, ?, ?, ?, CAST(? AS jsonb), 'DRAFT', ?, ?, ?)
            """, configuration.id(), configuration.gameType(), configuration.kind().name(), nextVersion,
            configuration.valuesJson(), actorId, Timestamp.from(configuration.updatedAt()),
            Timestamp.from(configuration.updatedAt()));
        audit("CONFIGURATION_CREATED", "CONFIGURATION", configuration.id(), actorId);
        return configuration(configuration.id());
    }

    @Override
    public Configuration updateConfiguration(Configuration configuration, UUID actorId) {
        int updated = jdbc.update("""
            UPDATE games.admin_configurations
               SET game_type=?, configuration_kind=?, values_json=CAST(? AS jsonb), updated_at=now()
             WHERE id=? AND status='DRAFT'
            """, configuration.gameType(), configuration.kind().name(), configuration.valuesJson(), configuration.id());
        if (updated != 1) throw new IllegalStateException("Seul un brouillon de configuration peut être modifié");
        audit("CONFIGURATION_UPDATED", "CONFIGURATION", configuration.id(), actorId);
        return configuration(configuration.id());
    }

    @Override
    public Configuration publishConfiguration(UUID configurationId, UUID actorId) {
        Configuration selected = configuration(configurationId);
        jdbc.update("UPDATE games.admin_configurations SET status='ARCHIVED', updated_at=now() WHERE game_type=? AND configuration_kind=? AND status='PUBLISHED' AND id<>?", selected.gameType(), selected.kind().name(), configurationId);
        int updated = jdbc.update("UPDATE games.admin_configurations SET status='PUBLISHED', published_at=now(), updated_at=now() WHERE id=? AND status='DRAFT'", configurationId);
        if (updated != 1) throw new IllegalStateException("Seule une configuration en brouillon peut être publiée");
        audit("CONFIGURATION_PUBLISHED", "CONFIGURATION", configurationId, actorId);
        return configuration(configurationId);
    }

    @Override
    public Configuration archiveConfiguration(UUID configurationId, UUID actorId) {
        int updated = jdbc.update("UPDATE games.admin_configurations SET status='ARCHIVED', updated_at=now() WHERE id=? AND status<>'ARCHIVED'", configurationId);
        if (updated != 1) throw new IllegalStateException("Configuration introuvable ou déjà archivée");
        audit("CONFIGURATION_ARCHIVED", "CONFIGURATION", configurationId, actorId);
        return configuration(configurationId);
    }

    @Override
    public void deleteConfigurationDraft(UUID configurationId, UUID actorId) {
        int deleted = jdbc.update("DELETE FROM games.admin_configurations WHERE id=? AND status='DRAFT'", configurationId);
        if (deleted != 1) throw new IllegalStateException("Seul un brouillon de configuration peut être supprimé");
        audit("CONFIGURATION_DELETED", "CONFIGURATION", configurationId, actorId);
    }

    @Override
    public List<Asset> assets() {
        return jdbc.query("SELECT * FROM games.admin_assets ORDER BY created_at DESC",
            (rs, row) -> asset(rs, row));
    }

    @Override
    public Optional<Asset> findAsset(UUID assetId) {
        return jdbc.query("SELECT * FROM games.admin_assets WHERE id=?",
            (rs, row) -> asset(rs, row), assetId).stream().findFirst();
    }

    @Override
    public Asset saveAsset(Asset asset, UUID actorId) {
        jdbc.update("""
            INSERT INTO games.admin_assets
              (id, game_type, filename, media_type, url, public_id, alt_text, status, created_by, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'DRAFT', ?, ?, ?)
            """, asset.id(), asset.gameType(), asset.filename(), asset.mediaType(), asset.url(),
            asset.publicId(), asset.altText(), actorId, Timestamp.from(asset.createdAt()), Timestamp.from(asset.createdAt()));
        audit("ASSET_UPLOADED", "ASSET", asset.id(), actorId);
        return asset;
    }

    @Override
    public Asset updateAsset(UUID assetId, String gameType, String altText, UUID actorId) {
        int updated = jdbc.update("""
            UPDATE games.admin_assets SET game_type=?, alt_text=?, updated_at=now()
             WHERE id=? AND status='DRAFT'
            """, gameType, altText, assetId);
        if (updated != 1) throw new IllegalStateException("Seul un asset en brouillon peut être modifié");
        audit("ASSET_UPDATED", "ASSET", assetId, actorId);
        return asset(assetId);
    }

    @Override
    public Asset changeAssetStatus(UUID assetId, Status status, UUID actorId) {
        int updated = jdbc.update("UPDATE games.admin_assets SET status=?, updated_at=now() WHERE id=?",
            status.name(), assetId);
        if (updated != 1) throw new IllegalArgumentException("Asset introuvable");
        audit("ASSET_" + status.name(), "ASSET", assetId, actorId);
        return asset(assetId);
    }

    @Override
    public void deleteAssetDraft(UUID assetId, UUID actorId) {
        int deleted = jdbc.update("DELETE FROM games.admin_assets WHERE id=? AND status='DRAFT'", assetId);
        if (deleted != 1) throw new IllegalStateException("Seul un asset en brouillon peut être supprimé");
        audit("ASSET_DELETED", "ASSET", assetId, actorId);
    }

    @Override
    public List<AuditEntry> auditEntries() {
        return jdbc.query("SELECT * FROM games.admin_audit_log ORDER BY created_at DESC LIMIT 200",
            (rs, row) -> new AuditEntry(uuid(rs, "id"), rs.getString("action"),
                rs.getString("entity_type"), uuid(rs, "entity_id"), uuid(rs, "actor_id"),
                rs.getString("details"), instant(rs, "created_at")));
    }

    private Configuration configuration(UUID id) {
        return jdbc.queryForObject("SELECT * FROM games.admin_configurations WHERE id=?",
            (rs, row) -> configuration(rs, row), id);
    }

    private Question question(ResultSet rs, int row) throws SQLException {
        return new Question(uuid(rs, "id"), rs.getString("external_code"),
            ContentType.valueOf(rs.getString("content_type")), rs.getString("prompt"),
            rs.getString("payload_json"), Status.valueOf(rs.getString("status")),
            rs.getString("bank_name"), uuidNullable(rs, "source_id"), rs.getBoolean("managed"),
            instant(rs, "updated_at"));
    }

    private Bank bank(ResultSet rs, int row) throws SQLException {
        return new Bank(uuid(rs, "id"), rs.getString("code"), rs.getString("name"),
            ContentType.valueOf(rs.getString("content_type")), rs.getInt("item_count"),
            rs.getInt("rotation_weight"), rs.getInt("version"),
            Status.valueOf(rs.getString("status")), instant(rs, "updated_at"));
    }

    private Configuration configuration(ResultSet rs, int row) throws SQLException {
        return new Configuration(uuid(rs, "id"), rs.getString("game_type"),
            ConfigurationKind.valueOf(rs.getString("configuration_kind")), rs.getInt("version"),
            rs.getString("values_json"), Status.valueOf(rs.getString("status")),
            instant(rs, "updated_at"));
    }

    private Asset asset(ResultSet rs, int row) throws SQLException {
        return new Asset(uuid(rs, "id"), rs.getString("game_type"), rs.getString("filename"),
            rs.getString("media_type"), rs.getString("url"), rs.getString("public_id"),
            rs.getString("alt_text"), Status.valueOf(rs.getString("status")), instant(rs, "created_at"));
    }

    private Asset asset(UUID id) {
        return jdbc.queryForObject("SELECT * FROM games.admin_assets WHERE id=?",
            (rs, row) -> asset(rs, row), id);
    }

    private void audit(String action, String entityType, UUID entityId, UUID actorId) {
        audit(action, entityType, entityId, actorId, "{}");
    }

    private void audit(String action, String entityType, UUID entityId, UUID actorId, String detailsJson) {
        jdbc.update("INSERT INTO games.admin_audit_log (id, action, entity_type, entity_id, actor_id, details) VALUES (?, ?, ?, ?, ?, CAST(? AS jsonb))",
            UUID.randomUUID(), action, entityType, entityId, actorId, detailsJson);
    }

    private Map<String, Object> jsonMap(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Configuration administrée persistée invalide", exception);
        }
    }

    private static UUID uuid(ResultSet rs, String column) throws SQLException { return rs.getObject(column, UUID.class); }
    private static UUID uuidNullable(ResultSet rs, String column) throws SQLException { return rs.getObject(column, UUID.class); }
    private static Instant instant(ResultSet rs, String column) throws SQLException { return rs.getTimestamp(column).toInstant(); }
    private static long orZero(Long value) { return value == null ? 0 : value; }
}
