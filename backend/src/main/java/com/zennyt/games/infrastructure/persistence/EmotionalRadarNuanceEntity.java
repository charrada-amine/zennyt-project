package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;

import java.io.Serializable;
import java.util.Objects;

/**
 * Définition JPA de la table {@code games.emotional_radar_nuances}.
 *
 * <p>Table de référence seedée (voir {@code db/seed}) et lue hors de l'application :
 * cette entité ne sert qu'à faire de JPA la source du schéma de la table.
 */
@Entity
@Table(name = "emotional_radar_nuances", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans emotional_radar_nuances_pkey).
    uniqueConstraints = @UniqueConstraint(name = "emotional_radar_nuances_pkey", columnNames = {"emotion", "nuance_key"}))
@Check(name = "ck_er_nuances_emotion", constraints = "emotion IN ('JOY', 'SADNESS', 'ANGER', 'FEAR', 'DISGUST', 'SURPRISE')")
@Check(name = "ck_er_nuances_source", constraints = "source IN ('FIGMA', 'PROVISIONAL')")
@IdClass(EmotionalRadarNuanceEntity.Key.class)
class EmotionalRadarNuanceEntity {

    @Id
    @Column(name = "emotion", nullable = false, length = 16)
    private String emotion;

    @Id
    @Column(name = "nuance_key", nullable = false, length = 64)
    private String nuanceKey;

    @Column(name = "label", nullable = false, length = 128)
    private String label;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "source", nullable = false, length = 16)
    private String source;

    protected EmotionalRadarNuanceEntity() {
    }

    /** Clé primaire composite (emotion, nuance_key). */
    public static class Key implements Serializable {
        private String emotion;
        private String nuanceKey;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(emotion, other.emotion)
                && Objects.equals(nuanceKey, other.nuanceKey);
        }

        @Override
        public int hashCode() {
            return Objects.hash(emotion, nuanceKey);
        }
    }
}
