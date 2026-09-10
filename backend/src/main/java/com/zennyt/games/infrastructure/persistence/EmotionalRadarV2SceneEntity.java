package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.DistanceBand;
import com.zennyt.games.domain.vo.RadarMediaStatus;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;
import com.zennyt.games.domain.vo.StimulusType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/** Entité technique d'une scène assignée à une session Emotional Radar V2. */
@Entity
@Table(name = "emotional_radar_v2_scenes", schema = "games")
@IdClass(EmotionalRadarV2SceneEntity.SceneId.class)
public class EmotionalRadarV2SceneEntity {

    public static class SceneId implements Serializable {
        private UUID sessionId;
        private int sceneOrder;

        public SceneId() {
        }

        public SceneId(UUID sessionId, int sceneOrder) {
            this.sessionId = sessionId;
            this.sceneOrder = sceneOrder;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof SceneId other)) return false;
            return sceneOrder == other.sceneOrder && Objects.equals(sessionId, other.sessionId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, sceneOrder);
        }
    }

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "scene_order", nullable = false)
    private int sceneOrder;

    @Column(nullable = false)
    private int level;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_distance_band", nullable = false, length = 16)
    private DistanceBand targetDistanceBand;

    @Column(name = "choice_keys", nullable = false, columnDefinition = "text")
    private String choiceKeys;

    @Column(name = "scene_difficulty", nullable = false)
    private double sceneDifficulty;

    @Column(name = "correct_emotion_key", nullable = false, length = 64)
    private String correctEmotionKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "stimulus_type", nullable = false, length = 16)
    private StimulusType stimulusType;

    @Column(name = "stimulus_intensity", nullable = false)
    private int stimulusIntensity;

    @Enumerated(EnumType.STRING)
    @Column(name = "media_status", nullable = false, length = 32)
    private RadarMediaStatus mediaStatus;

    @Column(name = "media_url", columnDefinition = "text")
    private String mediaUrl;

    @Column(name = "contextual_caption", columnDefinition = "text")
    private String contextualCaption;

    @Column(name = "sensitive_content_flag", nullable = false)
    private boolean sensitiveContentFlag;

    @Column(name = "served_at", nullable = false)
    private Instant servedAt;

    @Column(name = "selected_emotion_key", length = 64)
    private String selectedEmotionKey;

    @Column(name = "selected_intensity")
    private Integer selectedIntensity;

    @Column(name = "explanation", columnDefinition = "text")
    private String explanation;

    @Column(name = "response_time_ms")
    private Integer responseTimeMs;

    @Column(name = "timed_out")
    private Boolean timedOut;

    @Column(name = "impulsive")
    private Boolean impulsive;

    @Column(name = "semantic_error_distance")
    private Double semanticErrorDistance;

    @Column(name = "answered_at")
    private Instant answeredAt;

    protected EmotionalRadarV2SceneEntity() {
    }

    public static EmotionalRadarV2SceneEntity fromDomain(RadarV2SceneAssignment scene) {
        EmotionalRadarV2SceneEntity entity = new EmotionalRadarV2SceneEntity();
        entity.sessionId = scene.sessionId();
        entity.sceneOrder = scene.sceneOrder();
        entity.level = scene.level();
        entity.targetDistanceBand = scene.targetDistanceBand();
        entity.choiceKeys = String.join(",", scene.choiceKeys());
        entity.sceneDifficulty = scene.sceneDifficulty();
        entity.correctEmotionKey = scene.correctEmotionKey();
        entity.stimulusType = scene.stimulusType();
        entity.stimulusIntensity = scene.stimulusIntensity();
        entity.mediaStatus = scene.mediaStatus();
        entity.mediaUrl = scene.mediaUrl();
        entity.contextualCaption = scene.contextualCaption();
        entity.sensitiveContentFlag = scene.sensitiveContentFlag();
        entity.servedAt = scene.servedAt();
        entity.copyAnswer(scene);
        return entity;
    }

    public void applyFirstAnswer(RadarV2SceneAssignment scene) {
        if (answeredAt != null) {
            throw new IllegalStateException("réponse V2 déjà persistée : " + sceneOrder);
        }
        if (!sessionId.equals(scene.sessionId()) || sceneOrder != scene.sceneOrder()
            || !scene.answered()) {
            throw new IllegalArgumentException("affectation répondue incohérente");
        }
        copyAnswer(scene);
    }

    private void copyAnswer(RadarV2SceneAssignment scene) {
        selectedEmotionKey = scene.selectedEmotionKey();
        selectedIntensity = scene.selectedIntensity();
        explanation = scene.explanation();
        responseTimeMs = scene.responseTimeMs();
        timedOut = scene.timedOut();
        impulsive = scene.impulsive();
        semanticErrorDistance = scene.semanticErrorDistance();
        answeredAt = scene.answeredAt();
    }

    public RadarV2SceneAssignment toDomain() {
        List<String> keys = choiceKeys.isBlank()
            ? List.of() : Arrays.asList(choiceKeys.split(",", -1));
        return new RadarV2SceneAssignment(
            sessionId, sceneOrder, level, targetDistanceBand, keys,
            sceneDifficulty, correctEmotionKey, stimulusType, stimulusIntensity,
            mediaStatus, mediaUrl, contextualCaption, sensitiveContentFlag, servedAt,
            selectedEmotionKey, selectedIntensity, explanation, responseTimeMs,
            timedOut, impulsive, semanticErrorDistance, answeredAt);
    }

    public UUID getSessionId() { return sessionId; }
    public int getSceneOrder() { return sceneOrder; }
    public Instant getAnsweredAt() { return answeredAt; }
}
