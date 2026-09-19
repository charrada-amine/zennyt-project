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
 * Définition JPA de la table {@code games.coordination_tracking_runs}.
 *
 * <p>Les lectures et écritures passent par {@link CoordinationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "coordination_tracking_runs", schema = "games")
@Check(name = "ck_coord_accuracy_ranges", constraints = "provisional_accuracy_score >= 0 AND provisional_accuracy_score <= 100 AND overall_accuracy_percent >= 0 AND overall_accuracy_percent <= 100 AND fast_accuracy_percent >= 0 AND fast_accuracy_percent <= 100 AND slow_accuracy_percent >= 0 AND slow_accuracy_percent <= 100 AND long_accuracy_percent >= 0 AND long_accuracy_percent <= 100 AND short_accuracy_percent >= 0 AND short_accuracy_percent <= 100 AND average_center_distance >= 0 AND average_center_distance <= 1200")
@Check(name = "ck_coord_input_source", constraints = "input_source IN ('MOUSE', 'TOUCH', 'STYLUS')")
@Check(name = "ck_coord_protocol", constraints = "protocol_version = 'FIXED_SQUARE_CW_V1'")
@Check(name = "ck_coord_run_counts", constraints = "background_event_count >= 0 AND dropped_frame_count >= 0 AND test_execution_time_ms > 0 AND sample_count >= 0 AND absent_sample_count >= 0 AND absent_sample_count <= sample_count AND timing_deviation_count >= 0 AND sampling_gap_count >= 0")
@Check(name = "ck_coord_session_valid", constraints = "session_valid = (technical_valid AND task_valid)")
@Check(name = "ck_coord_task_valid", constraints = "task_valid = (accuracy_valid AND execution_time_valid)")
@Check(name = "ck_coord_technical_valid", constraints = "technical_valid = (session_completed AND NOT interrupted AND background_event_count = 0 AND timing_deviation_count = 0)")
class CoordinationTrackingRunEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "protocol_version", nullable = false, length = 32)
    private String protocolVersion;

    @Column(name = "input_source", nullable = false, length = 16)
    private String inputSource;

    @Column(name = "session_completed", nullable = false)
    private boolean sessionCompleted;

    @Column(name = "interrupted", nullable = false)
    private boolean interrupted;

    @Column(name = "background_event_count", nullable = false)
    private int backgroundEventCount;

    @Column(name = "dropped_frame_count", nullable = false)
    private int droppedFrameCount;

    @Column(name = "session_valid", nullable = false)
    private boolean sessionValid;

    @Column(name = "provisional_accuracy_score", nullable = false)
    private int provisionalAccuracyScore;

    @Column(name = "overall_accuracy_percent", nullable = false)
    private double overallAccuracyPercent;

    @Column(name = "fast_accuracy_percent", nullable = false)
    private double fastAccuracyPercent;

    @Column(name = "slow_accuracy_percent", nullable = false)
    private double slowAccuracyPercent;

    @Column(name = "long_accuracy_percent", nullable = false)
    private double longAccuracyPercent;

    @Column(name = "short_accuracy_percent", nullable = false)
    private double shortAccuracyPercent;

    @Column(name = "average_center_distance", nullable = false)
    private double averageCenterDistance;

    @Column(name = "test_execution_time_ms", nullable = false)
    private long testExecutionTimeMs;

    @Column(name = "accuracy_valid", nullable = false)
    private boolean accuracyValid;

    @Column(name = "execution_time_valid", nullable = false)
    private boolean executionTimeValid;

    @Column(name = "task_valid", nullable = false)
    private boolean taskValid;

    @Column(name = "technical_valid", nullable = false)
    private boolean technicalValid;

    @Column(name = "sample_count", nullable = false)
    private int sampleCount;

    @Column(name = "absent_sample_count", nullable = false)
    private int absentSampleCount;

    @Column(name = "timing_deviation_count", nullable = false)
    private int timingDeviationCount;

    @Column(name = "sampling_gap_count", nullable = false)
    private int samplingGapCount;

    @Column(name = "validity_issues", nullable = false, length = Length.LONG32)
    private String validityIssues;

    @ColumnDefault("now()")
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "coordination_tracking_runs_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    protected CoordinationTrackingRunEntity() {
    }
}
