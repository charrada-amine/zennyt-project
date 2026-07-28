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
@Table(name = "emotional_radar_answers", schema = "games")
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
