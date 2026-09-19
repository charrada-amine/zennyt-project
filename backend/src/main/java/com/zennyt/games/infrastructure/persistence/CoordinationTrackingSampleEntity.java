package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.coordination_tracking_samples}.
 *
 * <p>Les lectures et écritures passent par {@link CoordinationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "coordination_tracking_samples", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans coordination_tracking_samples_pkey).
    uniqueConstraints = @UniqueConstraint(name = "coordination_tracking_samples_pkey", columnNames = {"session_id", "segment_index", "sample_index"}))
@Check(name = "ck_coord_sample_index", constraints = "sample_index >= 1 AND sample_index <= 2000")
@Check(name = "ck_coord_sample_pointer", constraints = "pointer_present AND pointer_x >= 0 AND pointer_x <= 1000000 AND pointer_y >= 0 AND pointer_y <= 1000000 OR NOT pointer_present AND pointer_x IS NULL AND pointer_y IS NULL")
@Check(name = "ck_coord_sample_timestamp", constraints = "timestamp_ms >= 0")
@IdClass(CoordinationTrackingSampleEntity.Key.class)
class CoordinationTrackingSampleEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "segment_index", nullable = false)
    private int segmentIndex;

    @Id
    @Column(name = "sample_index", nullable = false)
    private int sampleIndex;

    @Column(name = "timestamp_ms", nullable = false)
    private long timestampMs;

    @Column(name = "pointer_present", nullable = false)
    private boolean pointerPresent;

    @Column(name = "pointer_x")
    private Integer pointerX;

    @Column(name = "pointer_y")
    private Integer pointerY;

    /** Clé étrangère {@code games.coordination_tracking_segments(session_id, segment_index) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumns(value = {
        @JoinColumn(name = "session_id", referencedColumnName = "session_id", insertable = false, updatable = false),
        @JoinColumn(name = "segment_index", referencedColumnName = "segment_index", insertable = false, updatable = false)},
        foreignKey = @ForeignKey(name = "coordination_tracking_samples_session_id_segment_index_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private CoordinationTrackingSegmentEntity coordinationTrackingSegment;

    protected CoordinationTrackingSampleEntity() {
    }

    /** Clé primaire composite (session_id, segment_index, sample_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int segmentIndex;
        private int sampleIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(segmentIndex, other.segmentIndex)
                && Objects.equals(sampleIndex, other.sampleIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, segmentIndex, sampleIndex);
        }
    }
}
