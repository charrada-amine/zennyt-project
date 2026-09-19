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
 * Définition JPA de la table {@code games.continuous_attention_runs}.
 *
 * <p>Les lectures et écritures passent par {@link ContinuousAttentionMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "continuous_attention_runs", schema = "games")
@Check(name = "ck_ca_protocol", constraints = "protocol_version = 'ROSVOLD_LONG_V1'")
@Check(name = "ck_ca_run_counts", constraints = "background_event_count >= 0 AND dropped_frame_count >= 0 AND timing_deviation_count >= 0")
class ContinuousAttentionRunEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "protocol_version", nullable = false, length = 32)
    private String protocolVersion;

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
        foreignKey = @ForeignKey(name = "continuous_attention_runs_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameSessionEntity session;

    protected ContinuousAttentionRunEntity() {
    }
}
