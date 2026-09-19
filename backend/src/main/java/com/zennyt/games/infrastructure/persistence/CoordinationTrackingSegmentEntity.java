package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
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
 * Définition JPA de la table {@code games.coordination_tracking_segments}.
 *
 * <p>Les lectures et écritures passent par {@link CoordinationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "coordination_tracking_segments", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans coordination_tracking_segments_pkey).
    uniqueConstraints = @UniqueConstraint(name = "coordination_tracking_segments_pkey", columnNames = {"session_id", "segment_index"}))
@Check(name = "ck_coord_segment_duration", constraints = "nominal_duration_ms IN (2333, 7000) AND actual_start_ms >= 0 AND actual_end_ms > actual_start_ms")
@Check(name = "ck_coord_segment_index", constraints = "segment_index >= 1 AND segment_index <= 14")
@Check(name = "ck_coord_segment_phase", constraints = "phase = 'PRACTICE' AND segment_index >= 1 AND segment_index <= 2 OR phase = 'TEST' AND segment_index >= 3 AND segment_index <= 14")
@Check(name = "ck_coord_segment_speed", constraints = "speed IN ('SLOW', 'FAST')")
@IdClass(CoordinationTrackingSegmentEntity.Key.class)
class CoordinationTrackingSegmentEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "segment_index", nullable = false)
    private int segmentIndex;

    @Column(name = "phase", nullable = false, length = 16)
    private String phase;

    @Column(name = "speed", nullable = false, length = 8)
    private String speed;

    @Column(name = "nominal_duration_ms", nullable = false)
    private int nominalDurationMs;

    @Column(name = "actual_start_ms", nullable = false)
    private long actualStartMs;

    @Column(name = "actual_end_ms", nullable = false)
    private long actualEndMs;

    /** Clé étrangère {@code games.coordination_tracking_runs(session_id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "coordination_tracking_segments_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private CoordinationTrackingRunEntity coordinationTrackingRun;

    protected CoordinationTrackingSegmentEntity() {
    }

    /** Clé primaire composite (session_id, segment_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int segmentIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(segmentIndex, other.segmentIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, segmentIndex);
        }
    }
}
