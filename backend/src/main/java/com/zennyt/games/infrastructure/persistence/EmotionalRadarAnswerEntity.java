package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
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
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Entité JPA d'une réponse notée (table {@code games.emotional_radar_answers}).
 *
 * <p>Clé composite {@code (session_id, scene_id)} : une seule réponse par scène et
 * par session, ce qui rend la validation idempotente.
 */
@Entity
// Trigger de contrainte ck_emotional_radar_answer_scene_reference (scene_id) : db/schema-complements.sql.
@Table(name = "emotional_radar_answers", schema = "games",
    // Ordre des colonnes de la clé primaire, fusionné dans emotional_radar_answers_pkey.
    uniqueConstraints = @UniqueConstraint(name = "emotional_radar_answers_pkey", columnNames = {"session_id", "scene_id"}),
    indexes = @Index(name = "ix_er_answers_session", columnList = "session_id"))
@Check(name = "ck_er_answers_intensity", constraints = "selected_intensity >= 1 AND selected_intensity <= 5")
@Check(name = "ck_er_answers_points", constraints = "emotion_points >= 0 AND emotion_points <= 3"
    + " AND nuance_points >= 0 AND nuance_points <= 4 AND intensity_points >= 0 AND intensity_points <= 2"
    + " AND scene_points >= 0 AND scene_points <= 10")
@IdClass(EmotionalRadarAnswerEntity.AnswerId.class)
public class EmotionalRadarAnswerEntity {

    /** Clé composite de l'entité. */
    public static class AnswerId implements Serializable {
        private UUID sessionId;
        private UUID sceneId;

        public AnswerId() {
        }

        public AnswerId(UUID sessionId, UUID sceneId) {
            this.sessionId = sessionId;
            this.sceneId = sceneId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (!(o instanceof AnswerId other)) {
                return false;
            }
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(sceneId, other.sceneId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, sceneId);
        }
    }

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "emotional_radar_answers_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    @Id
    @Column(name = "scene_id", nullable = false)
    private UUID sceneId;

    @Column(name = "scene_order", nullable = false)
    private int sceneOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "selected_emotion", nullable = false, length = 16)
    private BasicEmotion selectedEmotion;

    @Column(name = "selected_nuance", nullable = false, length = 64)
    private String selectedNuance;

    @Column(name = "selected_intensity", nullable = false)
    private int selectedIntensity;

    @Enumerated(EnumType.STRING)
    @Column(name = "expected_emotion", nullable = false, length = 16)
    private BasicEmotion expectedEmotion;

    @Column(name = "expected_nuance", nullable = false, length = 64)
    private String expectedNuance;

    @Column(name = "expected_intensity", nullable = false)
    private int expectedIntensity;

    @Column(name = "emotion_points", nullable = false)
    private int emotionPoints;

    @Column(name = "nuance_points", nullable = false)
    private int nuancePoints;

    @Column(name = "intensity_points", nullable = false)
    private int intensityPoints;

    @Column(name = "scene_points", nullable = false)
    private int scenePoints;

    @Column(name = "correct", nullable = false)
    private boolean correct;

    @Column(name = "answered_at", nullable = false)
    private Instant answeredAt;

    protected EmotionalRadarAnswerEntity() {
    }

    public static EmotionalRadarAnswerEntity fromDomain(EmotionalRadarAnswer a) {
        EmotionalRadarAnswerEntity e = new EmotionalRadarAnswerEntity();
        e.sessionId = a.sessionId();
        e.sceneId = a.sceneId();
        e.sceneOrder = a.sceneOrder();
        e.selectedEmotion = a.selectedEmotion();
        e.selectedNuance = a.selectedNuance();
        e.selectedIntensity = a.selectedIntensity();
        e.expectedEmotion = a.expectedEmotion();
        e.expectedNuance = a.expectedNuance();
        e.expectedIntensity = a.expectedIntensity();
        e.emotionPoints = a.emotionPoints();
        e.nuancePoints = a.nuancePoints();
        e.intensityPoints = a.intensityPoints();
        e.scenePoints = a.scenePoints();
        e.correct = a.correct();
        e.answeredAt = a.answeredAt();
        return e;
    }

    public EmotionalRadarAnswer toDomain() {
        return new EmotionalRadarAnswer(
            sessionId, sceneId, sceneOrder,
            selectedEmotion, selectedNuance, selectedIntensity,
            expectedEmotion, expectedNuance, expectedIntensity,
            emotionPoints, nuancePoints, intensityPoints, scenePoints,
            correct, answeredAt);
    }
}
