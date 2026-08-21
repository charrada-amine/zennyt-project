package com.zennyt.shared.application;

/**
 * Encodage/comparaison des empreintes numériques (embeddings) stockées en
 * colonnes texte (JSON d'un tableau de nombres) — évite une dépendance à une
 * extension Postgres type pgvector pour un volume qui reste modeste (142
 * métiers, une empreinte par candidat).
 */
public final class EmbeddingCodec {
    private EmbeddingCodec() {}

    public static String toJson(float[] embedding) {
        if (embedding == null) return null;
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < embedding.length; i++) {
            if (i > 0) json.append(',');
            json.append(embedding[i]);
        }
        return json.append(']').toString();
    }

    public static float[] fromJson(String json) {
        if (json == null || json.isBlank()) return null;
        String trimmed = json.trim();
        if (trimmed.length() < 2) return new float[0];
        String[] parts = trimmed.substring(1, trimmed.length() - 1).split(",");
        if (parts.length == 1 && parts[0].isBlank()) return new float[0];
        float[] values = new float[parts.length];
        for (int i = 0; i < parts.length; i++) {
            values[i] = Float.parseFloat(parts[i].trim());
        }
        return values;
    }

    /** @return similarité cosinus (0-1 après normalisation), ou {@code null} si l'une des deux empreintes manque. */
    public static Double cosineSimilarity(float[] a, float[] b) {
        if (a == null || b == null || a.length == 0 || b.length == 0 || a.length != b.length) return null;
        double dot = 0, normA = 0, normB = 0;
        for (int i = 0; i < a.length; i++) {
            dot += a[i] * b[i];
            normA += a[i] * a[i];
            normB += b[i] * b[i];
        }
        if (normA == 0 || normB == 0) return null;
        double cosine = dot / (Math.sqrt(normA) * Math.sqrt(normB));
        // Les embeddings de phrase donnent généralement une similarité cosinus dans [-1, 1] ;
        // on ramène à [0, 1] pour l'utiliser directement comme bonus de tri.
        return (cosine + 1) / 2;
    }
}
