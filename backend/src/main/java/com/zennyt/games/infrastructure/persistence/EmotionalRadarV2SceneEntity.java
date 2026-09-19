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
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/** Entité technique d'une scène assignée à une session Emotional Radar V2. */
@Entity
@Table(name = "emotional_radar_v2_scenes", schema = "games",
    // Ordre des colonnes de la clé primaire, fusionné dans emotional_radar_v2_scenes_pkey.
    uniqueConstraints = @UniqueConstraint(name = "emotional_radar_v2_scenes_pkey", columnNames = {"session_id", "scene_order"}),
    // Index unique ux_er_v2_target_per_session et trigger trg_er_v2_answer_immutable : db/schema-complements.sql.
    indexes = @Index(name = "ix_er_v2_scenes_session", columnList = "session_id, scene_order"))
@Check(name = "ck_er_v2_answer_all_or_none", constraints =
    "answered_at IS NULL AND selected_emotion_key IS NULL AND selected_intensity IS NULL AND explanation IS NULL"
    + " AND response_time_ms IS NULL AND timed_out IS NULL AND impulsive IS NULL AND semantic_error_distance IS NULL"
    + " OR answered_at IS NOT NULL AND selected_emotion_key IS NOT NULL AND selected_intensity >= 0"
    + " AND selected_intensity <= 2 AND explanation IS NOT NULL AND response_time_ms >= 0 AND timed_out IS NOT NULL"
    + " AND impulsive IS NOT NULL AND semantic_error_distance >= 0.0 AND semantic_error_distance <= 1.0")
@Check(name = "ck_er_v2_band", constraints = "target_distance_band IN ('HIGH', 'MEDIUM', 'LOW')")
@Check(name = "ck_er_v2_context_caption", constraints = "media_status <> 'READY' OR stimulus_type <> 'CONTEXTUAL'"
    + " OR contextual_caption IS NOT NULL AND contextual_caption <> ''")
@Check(name = "ck_er_v2_difficulty", constraints = "scene_difficulty >= 0.0 AND scene_difficulty <= 1.0")
@Check(name = "ck_er_v2_level", constraints = "level >= 1 AND level <= 4")
@Check(name = "ck_er_v2_media_status", constraints = "media_status IN ('PLACEHOLDER_PENDING', 'READY')")
@Check(name = "ck_er_v2_placeholder", constraints = "media_status <> 'PLACEHOLDER_PENDING' OR media_url IS NULL")
@Check(name = "ck_er_v2_ready_media", constraints = "media_status <> 'READY' OR media_url IS NOT NULL AND media_url <> ''")
@Check(name = "ck_er_v2_scene_order", constraints = "scene_order >= 1 AND scene_order <= 15")
@Check(name = "ck_er_v2_stimulus_intensity", constraints = "stimulus_intensity >= 0 AND stimulus_intensity <= 2")
@Check(name = "ck_er_v2_stimulus_type", constraints = "stimulus_type IN ('FACIAL', 'BODY', 'SOCIAL', 'CONTEXTUAL')")
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

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "emotional_radar_v2_scenes_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    @Id
    @Column(name = "scene_order", nullable = false)
    private int sceneOrder;

    @Column(nullable = false)
    private int level;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_distance_band", nullable = false, length = 16)
    private DistanceBand targetDistanceBand;

    @Column(name = "choice_keys", nullable = false, length = Length.LONG32)
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

    @Column(name = "media_url", length = Length.LONG32)
    private String mediaUrl;

    @Column(name = "contextual_caption", length = Length.LONG32)
    private String contextualCaption;

    @Column(name = "sensitive_content_flag", nullable = false)
    private boolean sensitiveContentFlag;

    @Column(name = "served_at", nullable = false)
    private Instant servedAt;

    @Column(name = "selected_emotion_key", length = 64)
    private String selectedEmotionKey;

    @Column(name = "selected_intensity")
    private Integer selectedIntensity;

    @Column(name = "explanation", length = Length.LONG32)
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
