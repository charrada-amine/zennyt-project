package com.zennyt.games.domain.model;

import java.time.Instant;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/** Domain records for the games administration console. No Spring/JPA concerns. */
public final class AdminModels {
    private AdminModels() {}

    public enum Status { DRAFT, PUBLISHED, ARCHIVED }
    public enum ContentType { DECISION_SCENARIO, EMOTIONAL_RADAR_SCENE }
    public enum ConfigurationKind { SETTINGS, MODIFIERS }

    public record Overview(long questionCount, long publishedBankCount,
                           long draftCount, long assetCount) {}

    public record Question(UUID id, String externalCode, ContentType contentType,
                           String prompt, String payloadJson, Status status,
                           String bankName, UUID sourceId, boolean managed,
                           Instant updatedAt) {
        public Question {
            Objects.requireNonNull(id);
            externalCode = required(externalCode, "externalCode", 64);
            Objects.requireNonNull(contentType);
            prompt = required(prompt, "prompt", 10_000);
            payloadJson = payloadJson == null ? "{}" : payloadJson;
            rejectScoringKeys(payloadJson);
            Objects.requireNonNull(status);
            Objects.requireNonNull(updatedAt);
        }
    }

    public record Bank(UUID id, String code, String name, ContentType contentType,
                       int itemCount, int rotationWeight, int version, Status status,
                       Instant updatedAt) {
        public Bank {
            Objects.requireNonNull(id);
            code = required(code, "code", 64).toUpperCase(Locale.ROOT);
            name = required(name, "name", 120);
            Objects.requireNonNull(contentType);
            if (rotationWeight < 0 || rotationWeight > 100) {
                throw new IllegalArgumentException("rotationWeight doit être compris entre 0 et 100");
            }
            if (version < 1 || itemCount < 0) throw new IllegalArgumentException("Version ou compteur invalide");
            Objects.requireNonNull(status);
            Objects.requireNonNull(updatedAt);
        }
    }

    public record Configuration(UUID id, String gameType, ConfigurationKind kind, int version,
                                String valuesJson, Status status, Instant updatedAt) {
        public Configuration {
            Objects.requireNonNull(id);
            gameType = required(gameType, "gameType", 48).toUpperCase(Locale.ROOT);
            Objects.requireNonNull(kind);
            if (version < 1) throw new IllegalArgumentException("La version doit être positive");
            valuesJson = required(valuesJson, "values", 100_000);
            rejectScoringKeys(valuesJson);
            Objects.requireNonNull(status);
            Objects.requireNonNull(updatedAt);
        }
    }

    public record Asset(UUID id, String gameType, String filename, String mediaType,
                        String url, String publicId, String altText, Status status,
                        Instant createdAt) {
        public Asset {
            Objects.requireNonNull(id);
            gameType = required(gameType, "gameType", 48).toUpperCase(Locale.ROOT);
            filename = required(filename, "filename", 255);
            if (!"PNG".equals(mediaType) && !"SVG".equals(mediaType)) {
                throw new IllegalArgumentException("Seuls PNG et SVG sont acceptés");
            }
            url = required(url, "url", 4_096);
            publicId = required(publicId, "publicId", 4_096);
            altText = required(altText, "altText", 2_000);
            Objects.requireNonNull(status);
            Objects.requireNonNull(createdAt);
        }
    }

    public record AuditEntry(UUID id, String action, String entityType,
                             UUID entityId, UUID actorId, String detailsJson,
                             Instant createdAt) {
        public AuditEntry {
            detailsJson = detailsJson == null ? "{}" : detailsJson;
        }
    }

    private static String required(String value, String field, int max) {
        if (value == null || value.isBlank() || value.length() > max) {
            throw new IllegalArgumentException(field + " est obligatoire et doit faire au plus " + max + " caractères");
        }
        return value.trim();
    }

    /** Prevents the generic JSON editor from becoming a backdoor into protected scoring. */
    private static void rejectScoringKeys(String json) {
        String normalized = json.toLowerCase(Locale.ROOT);
        String[] forbidden = {"score", "barème", "bareme", "multiplier", "streak", "bonus", "points", "theta", "weight_score"};
        for (String key : forbidden) {
            if (normalized.contains("\"" + key)) {
                throw new IllegalArgumentException("Clé de scoring protégée interdite : " + key);
            }
        }
    }
}
