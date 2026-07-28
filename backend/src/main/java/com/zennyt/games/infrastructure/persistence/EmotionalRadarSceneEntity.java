package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.SceneMediaType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

/** Entité JPA d'une scène « Emotional Radar » (table {@code games.emotional_radar_scenes}). */
@Entity
@Table(name = "emotional_radar_scenes", schema = "games")
public class EmotionalRadarSceneEntity {

    @Id
    private UUID id;

    @Column(name = "scene_order", nullable = false)
    private int sceneOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "media_type", nullable = false, length = 16)
    private SceneMediaType mediaType;

    @Column(name = "prompt_text", nullable = false)
    private String promptText;

    @Column(name = "instruction_text", nullable = false)
    private String instructionText;

    @Column(name = "media_url")
    private String mediaUrl;

    @Column(name = "media_public_id")
    private String mediaPublicId;

    @Column(name = "alt_text")
    private String altText;

    @Column(name = "transcript")
    private String transcript;

    @Enumerated(EnumType.STRING)
    @Column(name = "expected_emotion", nullable = false, length = 16)
    private BasicEmotion expectedEmotion;

    @Column(name = "expected_nuance", nullable = false, length = 64)
    private String expectedNuance;

    @Column(name = "expected_intensity", nullable = false)
    private int expectedIntensity;

    @Column(name = "explanation", nullable = false)
    private String explanation;

    @Column(name = "active", nullable = false)
    private boolean active;

    protected EmotionalRadarSceneEntity() {
    }

    /** Mappe vers le VO domaine (qui revalide les invariants d'accessibilité). */
    public EmotionalRadarScene toDomain() {
        return new EmotionalRadarScene(
            id, sceneOrder, mediaType, promptText, instructionText,
            mediaUrl, mediaPublicId, altText, transcript,
            expectedEmotion, expectedNuance, expectedIntensity, explanation);
    }

    public UUID getId() {
        return id;
    }

    public boolean isActive() {
        return active;
    }

    public SceneMediaType getMediaType() {
        return mediaType;
    }

    /** Rattache un média téléversé et réactive la scène si elle devient complète. */
    public void attachMedia(String url, String publicId, String newAltText, String newTranscript) {
        this.mediaUrl = url;
        this.mediaPublicId = publicId;
        if (newAltText != null && !newAltText.isBlank()) {
            this.altText = newAltText;
        }
        if (newTranscript != null && !newTranscript.isBlank()) {
            this.transcript = newTranscript;
        }
        // Une scène média n'est jouable qu'une fois son équivalent textuel présent.
        boolean altOk = altText != null && !altText.isBlank();
        boolean transcriptOk = !mediaType.requiresTranscript()
            || (transcript != null && !transcript.isBlank());
        this.active = altOk && transcriptOk;
    }
}
