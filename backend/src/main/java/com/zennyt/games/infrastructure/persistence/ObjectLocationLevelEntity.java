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
 * Définition JPA de la table {@code games.object_location_levels}.
 *
 * <p>Les lectures et écritures passent par {@link ObjectLocationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "object_location_levels", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans object_location_levels_pkey).
    uniqueConstraints = @UniqueConstraint(name = "object_location_levels_pkey", columnNames = {"session_id", "level_index"}))
@Check(name = "ck_object_location_level_actions", constraints = "action_count >= 0 AND action_count <= 256 AND reposition_count >= 0 AND (average_first_placement_interval_ms IS NULL OR average_first_placement_interval_ms >= 0)")
@Check(name = "ck_object_location_level_categories", constraints = "exact_count >= 0 AND swap_count >= 0 AND local_error_count >= 0 AND global_error_count >= 0 AND (exact_count + swap_count + local_error_count + global_error_count + unplaced_count) = object_count AND unplaced_count >= 0 AND exact_accuracy_percent >= 0 AND exact_accuracy_percent <= 100 AND average_displacement_cells >= 0 AND average_displacement_cells <= sqrt(18)")
@Check(name = "ck_object_location_level_completion", constraints = "NOT timed_out OR completed")
@Check(name = "ck_object_location_level_durations", constraints = "actual_encoding_duration_ms >= 0 AND actual_encoding_duration_ms <= (object_count * 1500 + 250) AND actual_retention_duration_ms >= 0 AND actual_retention_duration_ms <= 2250 AND actual_recall_duration_ms >= 0 AND actual_recall_duration_ms <= (object_count * 4000 + 250)")
@Check(name = "ck_object_location_level_identity", constraints = "phase = 'PRACTICE' AND level_index = 0 AND object_count = 2 OR phase = 'TEST' AND level_index >= 1 AND level_index <= 6 AND object_count = (level_index + 2)")
@IdClass(ObjectLocationLevelEntity.Key.class)
class ObjectLocationLevelEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "level_index", nullable = false)
    private int levelIndex;

    @Column(name = "phase", nullable = false, length = 16)
    private String phase;

    @Column(name = "object_count", nullable = false)
    private int objectCount;

    @Column(name = "actual_encoding_duration_ms", nullable = false)
    private int actualEncodingDurationMs;

    @Column(name = "actual_retention_duration_ms", nullable = false)
    private int actualRetentionDurationMs;

    @Column(name = "actual_recall_duration_ms", nullable = false)
    private int actualRecallDurationMs;

    @Column(name = "timed_out", nullable = false)
    private boolean timedOut;

    @Column(name = "completed", nullable = false)
    private boolean completed;

    @Column(name = "passed", nullable = false)
    private boolean passed;

    @Column(name = "exact_count", nullable = false)
    private int exactCount;

    @Column(name = "swap_count", nullable = false)
    private int swapCount;

    @Column(name = "local_error_count", nullable = false)
    private int localErrorCount;

    @Column(name = "global_error_count", nullable = false)
    private int globalErrorCount;

    @Column(name = "unplaced_count", nullable = false)
    private int unplacedCount;

    @Column(name = "exact_accuracy_percent", nullable = false)
    private double exactAccuracyPercent;

    @Column(name = "average_displacement_cells", nullable = false)
    private double averageDisplacementCells;

    @Column(name = "action_count", nullable = false)
    private int actionCount;

    @Column(name = "reposition_count", nullable = false)
    private int repositionCount;

    @Column(name = "average_first_placement_interval_ms")
    private Double averageFirstPlacementIntervalMs;

    /** Clé étrangère {@code games.object_location_runs(session_id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "object_location_levels_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ObjectLocationRunEntity objectLocationRun;

    protected ObjectLocationLevelEntity() {
    }

    /** Clé primaire composite (session_id, level_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int levelIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(levelIndex, other.levelIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, levelIndex);
        }
    }
}
