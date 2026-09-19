package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.object_location_runs}.
 *
 * <p>Les lectures et écritures passent par {@link ObjectLocationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "object_location_runs", schema = "games")
@Check(name = "ck_object_location_classification", constraints = "exact_placement_count >= 0 AND swap_count >= 0 AND local_error_count >= 0 AND global_error_count >= 0 AND (exact_placement_count + swap_count + local_error_count + global_error_count + unplaced_count) = administered_object_count AND unplaced_count >= 0")
@Check(name = "ck_object_location_completion", constraints = "completion_reason IN ('MAX_LEVELS', 'STOP_RULE') AND session_completed OR completion_reason = 'TECHNICAL_INTERRUPTION' AND NOT session_completed")
@Check(name = "ck_object_location_level_counts", constraints = "completed_level_count >= 0 AND completed_level_count <= 6 AND passed_level_count >= 0 AND passed_level_count <= completed_level_count AND administered_object_count >= 0 AND administered_object_count <= 33")
@Check(name = "ck_object_location_minimum_levels", constraints = "minimum_levels_valid = (completed_level_count >= 3)")
@Check(name = "ck_object_location_protocol", constraints = "protocol_version = 'OBJECT_LOCATION_FINE_V1'")
@Check(name = "ck_object_location_ranges", constraints = "provisional_accuracy_score >= 0 AND provisional_accuracy_score <= 100 AND exact_accuracy_percent >= 0 AND exact_accuracy_percent <= 100 AND swap_rate_percent >= 0 AND swap_rate_percent <= 100 AND local_error_rate_percent >= 0 AND local_error_rate_percent <= 100 AND global_error_rate_percent >= 0 AND global_error_rate_percent <= 100 AND average_displacement_cells >= 0 AND average_displacement_cells <= sqrt(18) AND span >= 0 AND span <= 8 AND (average_first_placement_interval_ms IS NULL OR average_first_placement_interval_ms >= 0)")
@Check(name = "ck_object_location_session_valid", constraints = "session_valid = (technical_valid AND minimum_levels_valid AND progression_valid)")
@Check(name = "ck_object_location_technical_counts", constraints = "background_event_count >= 0 AND focus_loss_count >= 0 AND orientation_change_count >= 0 AND dropped_frame_count >= 0 AND reposition_count >= 0 AND timing_deviation_count >= 0")
@Check(name = "ck_object_location_technical_valid", constraints = "technical_valid = (session_completed AND NOT interrupted AND background_event_count = 0 AND focus_loss_count = 0 AND orientation_change_count = 0 AND timing_valid)")
@Check(name = "ck_object_location_timing_valid", constraints = "timing_valid = (timing_deviation_count = 0)")
class ObjectLocationRunEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "protocol_version", nullable = false, length = 40)
    private String protocolVersion;

    @Column(name = "completion_reason", nullable = false, length = 32)
    private String completionReason;

    @Column(name = "session_completed", nullable = false)
    private boolean sessionCompleted;

    @Column(name = "interrupted", nullable = false)
    private boolean interrupted;

    @Column(name = "background_event_count", nullable = false)
    private int backgroundEventCount;

    @Column(name = "focus_loss_count", nullable = false)
    private int focusLossCount;

    @Column(name = "orientation_change_count", nullable = false)
    private int orientationChangeCount;

    @Column(name = "dropped_frame_count", nullable = false)
    private int droppedFrameCount;

    @Column(name = "session_valid", nullable = false)
    private boolean sessionValid;

    @Column(name = "technical_valid", nullable = false)
    private boolean technicalValid;

    @Column(name = "minimum_levels_valid", nullable = false)
    private boolean minimumLevelsValid;

    @Column(name = "progression_valid", nullable = false)
    private boolean progressionValid;

    @Column(name = "timing_valid", nullable = false)
    private boolean timingValid;

    @Column(name = "provisional_accuracy_score", nullable = false)
    private int provisionalAccuracyScore;

    @Column(name = "completed_level_count", nullable = false)
    private int completedLevelCount;

    @Column(name = "passed_level_count", nullable = false)
    private int passedLevelCount;

    @Column(name = "administered_object_count", nullable = false)
    private int administeredObjectCount;

    @Column(name = "exact_placement_count", nullable = false)
    private int exactPlacementCount;

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

    @Column(name = "swap_rate_percent", nullable = false)
    private double swapRatePercent;

    @Column(name = "local_error_rate_percent", nullable = false)
    private double localErrorRatePercent;

    @Column(name = "global_error_rate_percent", nullable = false)
    private double globalErrorRatePercent;

    @Column(name = "average_displacement_cells", nullable = false)
    private double averageDisplacementCells;

    @Column(name = "span", nullable = false)
    private int span;

    @Column(name = "load_slope")
    private Double loadSlope;

    @Column(name = "average_first_placement_interval_ms")
    private Double averageFirstPlacementIntervalMs;

    @Column(name = "reposition_count", nullable = false)
    private int repositionCount;

    @Column(name = "timing_deviation_count", nullable = false)
    private int timingDeviationCount;

    @Column(name = "validity_issues", nullable = false, length = Length.LONG32)
    private String validityIssues;

    @ColumnDefault("now()")
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "object_location_runs_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    protected ObjectLocationRunEntity() {
    }
}
