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
 * Définition JPA de la table {@code games.bart_runs}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "bart_runs", schema = "games")
@Check(name = "ck_bart_counts", constraints = "background_event_count >= 0 AND focus_loss_count >= 0 AND test_balloon_count >= 0 AND test_balloon_count <= 30 AND collected_count >= 0 AND explosion_count >= 0 AND (collected_count + explosion_count) = test_balloon_count")
@Check(name = "ck_bart_protocol", constraints = "protocol_version = 'BART_LEJUEZ_V1'")
@Check(name = "ck_bart_ranges", constraints = "total_earnings >= 0 AND ev_optimal_earnings >= 0 AND optimal_fixed_pumps >= 0 AND optimal_fixed_pumps <= 127 AND efficiency_percent >= 0 AND efficiency_percent <= 100 AND (adjusted_average_pumps IS NULL OR adjusted_average_pumps >= 0 AND adjusted_average_pumps <= 127)")
@Check(name = "ck_bart_valid", constraints = "session_valid = (validity_issues = '')")
class BartRunEntity {

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

    @Column(name = "test_balloon_count", nullable = false)
    private int testBalloonCount;

    @Column(name = "collected_count", nullable = false)
    private int collectedCount;

    @Column(name = "explosion_count", nullable = false)
    private int explosionCount;

    @Column(name = "adjusted_average_pumps")
    private Double adjustedAveragePumps;

    @Column(name = "total_earnings", nullable = false)
    private int totalEarnings;

    @Column(name = "ev_optimal_earnings", nullable = false)
    private int evOptimalEarnings;

    @Column(name = "optimal_fixed_pumps", nullable = false)
    private int optimalFixedPumps;

    @Column(name = "efficiency_percent", nullable = false)
    private int efficiencyPercent;

    @Column(name = "mean_pumps_after_explosion")
    private Double meanPumpsAfterExplosion;

    @Column(name = "mean_pumps_after_collect")
    private Double meanPumpsAfterCollect;

    @Column(name = "median_inter_pump_interval_ms")
    private Double medianInterPumpIntervalMs;

    @ColumnDefault("now()")
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    /** Clé étrangère {@code games.game_sessions(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "bart_runs_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    protected BartRunEntity() {
    }
}
