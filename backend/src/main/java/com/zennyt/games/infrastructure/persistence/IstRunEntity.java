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
 * Définition JPA de la table {@code games.ist_runs}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "ist_runs", schema = "games")
@Check(name = "ck_ist_counts", constraints = "background_event_count >= 0 AND focus_loss_count >= 0 AND test_trial_count >= 0 AND test_trial_count <= 20 AND correct_count >= 0 AND correct_count <= test_trial_count AND random_response_count >= 0 AND random_response_count <= test_trial_count AND confidence_response_count >= 0 AND confidence_response_count <= test_trial_count")
@Check(name = "ck_ist_protocol", constraints = "protocol_version = 'IST_CLARK_V1'")
@Check(name = "ck_ist_ranges", constraints = "accuracy_percent >= 0 AND accuracy_percent <= 100 AND mean_boxes_fixed_win >= 0 AND mean_boxes_fixed_win <= 25 AND mean_boxes_decreasing_win >= 0 AND mean_boxes_decreasing_win <= 25 AND mean_p_correct_at_decision >= 0 AND mean_p_correct_at_decision <= 1 AND provisional_score >= 0 AND provisional_score <= 100 AND (calibration_bias IS NULL OR calibration_bias >= -1 AND calibration_bias <= 1)")
@Check(name = "ck_ist_valid", constraints = "session_valid = (validity_issues = '')")
class IstRunEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "protocol_version", nullable = false, length = 40)
    private String protocolVersion;

    @Column(name = "session_completed", nullable = false)
    private boolean sessionCompleted;

    @Column(name = "interrupted", nullable = false)
    private boolean interrupted;

    @Column(name = "background_event_count", nullable = false)
    private int backgroundEventCount;

    @Column(name = "focus_loss_count", nullable = false)
    private int focusLossCount;

    @Column(name = "session_valid", nullable = false)
    private boolean sessionValid;

    @Column(name = "validity_issues", nullable = false, length = Length.LONG32)
    private String validityIssues;

    @Column(name = "test_trial_count", nullable = false)
    private int testTrialCount;

    @Column(name = "correct_count", nullable = false)
    private int correctCount;

    @Column(name = "accuracy_percent", nullable = false)
    private double accuracyPercent;

    @Column(name = "mean_boxes_fixed_win", nullable = false)
    private double meanBoxesFixedWin;

    @Column(name = "mean_boxes_decreasing_win", nullable = false)
    private double meanBoxesDecreasingWin;

    @Column(name = "condition_discrimination", nullable = false)
    private double conditionDiscrimination;

    @Column(name = "mean_p_correct_at_decision", nullable = false)
    private double meanPCorrectAtDecision;

    @Column(name = "mean_p_correct_fixed_win", nullable = false)
    private double meanPCorrectFixedWin;

    @Column(name = "mean_p_correct_decreasing_win", nullable = false)
    private double meanPCorrectDecreasingWin;

    @Column(name = "total_earnings", nullable = false)
    private int totalEarnings;

    @Column(name = "random_response_count", nullable = false)
    private int randomResponseCount;

    @Column(name = "median_inter_action_interval_ms")
    private Double medianInterActionIntervalMs;

    @Column(name = "confidence_response_count", nullable = false)
    private int confidenceResponseCount;

    @Column(name = "calibration_bias")
    private Double calibrationBias;

    @Column(name = "provisional_score", nullable = false)
    private int provisionalScore;

    @ColumnDefault("now()")
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "ist_runs_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    protected IstRunEntity() {
    }
}
