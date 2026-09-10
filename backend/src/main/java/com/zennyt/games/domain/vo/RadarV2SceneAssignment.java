package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.service.SemanticDistanceModel;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Scène Emotional Radar V2 assignée à une session.
 *
 * <p>La clé correcte et l'intensité jouée restent côté serveur. Une affectation
 * passe une seule fois de « en attente » à « répondue » ; le dépôt et la base
 * interdisent ensuite toute réécriture de la réponse.
 */
public record RadarV2SceneAssignment(
    UUID sessionId,
    int sceneOrder,
    int level,
    DistanceBand targetDistanceBand,
    List<String> choiceKeys,
    double sceneDifficulty,
    String correctEmotionKey,
    StimulusType stimulusType,
    int stimulusIntensity,
    RadarMediaStatus mediaStatus,
    String mediaUrl,
    String contextualCaption,
    boolean sensitiveContentFlag,
    Instant servedAt,
    String selectedEmotionKey,
    Integer selectedIntensity,
    String explanation,
    Integer responseTimeMs,
    Boolean timedOut,
    Boolean impulsive,
    Double semanticErrorDistance,
    Instant answeredAt
) {

    public RadarV2SceneAssignment {
        if (sessionId == null || servedAt == null) {
            throw new IllegalArgumentException("sessionId et servedAt requis");
        }
        if (sceneOrder < 1 || sceneOrder > EmotionalRadarV2Config.TOTAL_SCENES) {
            throw new IllegalArgumentException("sceneOrder hors 1..15 : " + sceneOrder);
        }
        DifficultyLevel difficulty = EmotionalRadarV2Config.level(level);
        if (targetDistanceBand != difficulty.targetDistance()) {
            throw new IllegalArgumentException("bande incohérente avec le niveau " + level);
        }
        choiceKeys = choiceKeys == null ? List.of() : List.copyOf(choiceKeys);
        if (choiceKeys.size() != difficulty.choicesCount()
            || choiceKeys.stream().anyMatch(key -> key == null || key.isBlank())
            || choiceKeys.stream().distinct().count() != choiceKeys.size()) {
            throw new IllegalArgumentException("choix invalides pour le niveau " + level);
        }
        if (correctEmotionKey == null || !choiceKeys.contains(correctEmotionKey)) {
            throw new IllegalArgumentException("émotion correcte absente des choix");
        }
        if (sceneDifficulty < 0.0 || sceneDifficulty > 1.0) {
            throw new IllegalArgumentException("sceneDifficulty hors [0,1]");
        }
        if (stimulusType == null || stimulusIntensity < 0
            || stimulusIntensity >= EmotionalRadarV2Config.STIMULUS_INTENSITY_LEVELS.size()) {
            throw new IllegalArgumentException("stimulusType/intensité invalides");
        }
        if (mediaStatus == null) {
            throw new IllegalArgumentException("mediaStatus requis");
        }
        if (mediaStatus == RadarMediaStatus.PLACEHOLDER_PENDING && mediaUrl != null) {
            throw new IllegalArgumentException("un placeholder ne porte pas de média");
        }
        if (mediaStatus == RadarMediaStatus.READY) {
            if (mediaUrl == null || mediaUrl.isBlank()) {
                throw new IllegalArgumentException("mediaUrl requis pour un média prêt");
            }
            if (stimulusType.requiresContextualCaption()
                && (contextualCaption == null || contextualCaption.isBlank())) {
                throw new IllegalArgumentException("légende requise pour un stimulus contextuel");
            }
        }
        boolean hasAnyAnswerField = selectedEmotionKey != null || selectedIntensity != null
            || explanation != null || responseTimeMs != null || timedOut != null
            || impulsive != null || semanticErrorDistance != null || answeredAt != null;
        if (hasAnyAnswerField && (selectedEmotionKey == null || selectedIntensity == null
            || explanation == null || responseTimeMs == null || timedOut == null
            || impulsive == null || semanticErrorDistance == null || answeredAt == null)) {
            throw new IllegalArgumentException("réponse V2 partielle interdite");
        }
        if (answeredAt != null) {
            if (!choiceKeys.contains(selectedEmotionKey)) {
                throw new IllegalArgumentException("émotion choisie absente des choix servis");
            }
            if (selectedIntensity < 0
                || selectedIntensity >= EmotionalRadarV2Config.INTENSITY_SCALE.size()) {
                throw new IllegalArgumentException("intensité perçue hors 0..2");
            }
            if (explanation.isBlank() || explanation.length() > 2000) {
                throw new IllegalArgumentException("explication requise (1..2000 caractères)");
            }
            if (responseTimeMs < 0 || responseTimeMs > EmotionalRadarV2Config.MAX_RESPONSE_TIME_MS) {
                throw new IllegalArgumentException("temps de réponse hors plage");
            }
            if (semanticErrorDistance < 0.0 || semanticErrorDistance > 1.0) {
                throw new IllegalArgumentException("distance d'erreur hors [0,1]");
            }
        }
    }

    public static RadarV2SceneAssignment pending(
            UUID sessionId, int sceneOrder, int level, List<String> choiceKeys,
            double sceneDifficulty, String correctEmotionKey, StimulusType stimulusType,
            int stimulusIntensity, boolean sensitiveContentFlag, Instant servedAt) {
        return new RadarV2SceneAssignment(
            sessionId, sceneOrder, level, EmotionalRadarV2Config.level(level).targetDistance(),
            choiceKeys, sceneDifficulty, correctEmotionKey, stimulusType, stimulusIntensity,
            RadarMediaStatus.PLACEHOLDER_PENDING, null, null, sensitiveContentFlag, servedAt,
            null, null, null, null, null, null, null, null);
    }

    public boolean answered() {
        return answeredAt != null;
    }

    /** Corrige une réponse brute et retourne une nouvelle valeur immuable. */
    public RadarV2SceneAssignment answer(
            String selectedKey, int perceivedIntensity, String rawExplanation,
            long serverElapsedMs, EmotionReferential referential,
            SemanticDistanceModel distanceModel, Instant now) {
        if (answered()) {
            throw new IllegalStateException("scène déjà répondue : " + sceneOrder);
        }
        String normalizedKey = selectedKey == null ? null : selectedKey.trim();
        if (!choiceKeys.contains(normalizedKey)) {
            throw new IllegalArgumentException("émotion non proposée : " + selectedKey);
        }
        if (perceivedIntensity < 0
            || perceivedIntensity >= EmotionalRadarV2Config.INTENSITY_SCALE.size()) {
            throw new IllegalArgumentException("intensité perçue hors 0..2");
        }
        String normalizedExplanation = rawExplanation == null ? null : rawExplanation.trim();
        if (normalizedExplanation == null || normalizedExplanation.isBlank()
            || normalizedExplanation.length() > 2000) {
            throw new IllegalArgumentException("explication requise (1..2000 caractères)");
        }
        long nonNegativeElapsed = Math.max(0L, serverElapsedMs);
        boolean didTimeOut = nonNegativeElapsed > EmotionalRadarV2Config.MAX_RESPONSE_TIME_MS;
        int measuredMs = (int) Math.min(nonNegativeElapsed,
            EmotionalRadarV2Config.MAX_RESPONSE_TIME_MS);
        boolean wasImpulsive = nonNegativeElapsed < EmotionalRadarV2Config.MIN_IMPULSIVE_TIME_MS;

        EmotionDefinition correct = referential.byKey(correctEmotionKey)
            .orElseThrow(() -> new IllegalStateException("émotion correcte inconnue"));
        EmotionDefinition selected = referential.byKey(normalizedKey)
            .orElseThrow(() -> new IllegalArgumentException("émotion choisie inconnue"));
        double errorDistance = normalizedKey.equals(correctEmotionKey)
            ? 0.0 : distanceModel.distance(correct, selected);

        return new RadarV2SceneAssignment(
            sessionId, sceneOrder, level, targetDistanceBand, choiceKeys,
            sceneDifficulty, correctEmotionKey, stimulusType, stimulusIntensity,
            mediaStatus, mediaUrl, contextualCaption, sensitiveContentFlag, servedAt,
            normalizedKey, perceivedIntensity, normalizedExplanation, measuredMs,
            didTimeOut, wasImpulsive, errorDistance, now);
    }

    /** Projection autoritaire vers la brique de scoring/reporting. */
    public RadarSceneOutcome outcome() {
        if (!answered()) {
            throw new IllegalStateException("scène non répondue : " + sceneOrder);
        }
        boolean correct = selectedEmotionKey.equals(correctEmotionKey) && !timedOut;
        return new RadarSceneOutcome(
            sceneOrder, level, choiceKeys.size(), sceneDifficulty,
            targetDistanceBand, stimulusType, correctEmotionKey, selectedEmotionKey,
            correct, semanticErrorDistance, stimulusIntensity, selectedIntensity,
            responseTimeMs, impulsive, -1, timedOut);
    }
}
