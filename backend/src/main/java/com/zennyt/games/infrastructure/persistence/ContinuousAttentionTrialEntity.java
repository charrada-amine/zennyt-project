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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.continuous_attention_trials}.
 *
 * <p>Les lectures et écritures passent par {@link ContinuousAttentionMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "continuous_attention_trials", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans continuous_attention_trials_pkey).
    uniqueConstraints = @UniqueConstraint(name = "continuous_attention_trials_pkey", columnNames = {"session_id", "phase", "block_index", "trial_index"}))
@Check(name = "ck_ca_trial_block", constraints = "phase IN ('X_PRACTICE', 'AX_PRACTICE') AND block_index >= 1 AND block_index <= 2 OR phase IN ('X_TEST', 'AX_TEST') AND block_index >= 1 AND block_index <= 20")
@Check(name = "ck_ca_trial_correct", constraints = "correct IN (0, 1)")
@Check(name = "ck_ca_trial_index", constraints = "trial_index >= 1 AND trial_index <= 31")
@Check(name = "ck_ca_trial_latency_timestamp", constraints = "response_timestamp_ms IS NULL OR (response_timestamp_ms - actual_onset_ms) = latency_ms")
@Check(name = "ck_ca_trial_letters", constraints = "(previous_letter IS NULL OR previous_letter ~ '^[A-Z]$') AND current_letter ~ '^[A-Z]$'")
@Check(name = "ck_ca_trial_nonnegative", constraints = "scheduled_onset_ms >= 0 AND actual_onset_ms >= 0 AND actual_display_duration_ms >= 0 AND actual_isi_duration_ms >= 0 AND extra_response_count >= 0")
@Check(name = "ck_ca_trial_phase", constraints = "phase IN ('X_PRACTICE', 'X_TEST', 'AX_PRACTICE', 'AX_TEST')")
@Check(name = "ck_ca_trial_response", constraints = "response_code = 0 AND latency_ms IS NULL AND response_timestamp_ms IS NULL AND input_source IS NULL OR response_code = 57 AND latency_ms >= 0 AND latency_ms < 690 AND response_timestamp_ms IS NOT NULL AND input_source IN ('TOUCH', 'KEYBOARD')")
@IdClass(ContinuousAttentionTrialEntity.Key.class)
class ContinuousAttentionTrialEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "phase", nullable = false, length = 16)
    private String phase;

    @Id
    @Column(name = "block_index", nullable = false)
    private int blockIndex;

    @Id
    @Column(name = "trial_index", nullable = false)
    private int trialIndex;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "previous_letter", length = 1)
    private String previousLetter;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "current_letter", nullable = false, length = 1)
    private String currentLetter;

    @Column(name = "response_code", nullable = false)
    private int responseCode;

    @Column(name = "correct", nullable = false)
    private int correct;

    @Column(name = "latency_ms")
    private Integer latencyMs;

    @Column(name = "scheduled_onset_ms", nullable = false)
    private long scheduledOnsetMs;

    @Column(name = "actual_onset_ms", nullable = false)
    private long actualOnsetMs;

    @Column(name = "response_timestamp_ms")
    private Long responseTimestampMs;

    @Column(name = "actual_display_duration_ms", nullable = false)
    private int actualDisplayDurationMs;

    @Column(name = "actual_isi_duration_ms", nullable = false)
    private int actualIsiDurationMs;

    @Column(name = "input_source", length = 16)
    private String inputSource;

    @Column(name = "extra_response_count", nullable = false)
    private int extraResponseCount;

    @Column(name = "interrupted", nullable = false)
    private boolean interrupted;

    /** Clé étrangère {@code games.continuous_attention_runs(session_id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "continuous_attention_trials_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ContinuousAttentionRunEntity continuousAttentionRun;

    protected ContinuousAttentionTrialEntity() {
    }

    /** Clé primaire composite (session_id, phase, block_index, trial_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private String phase;
        private int blockIndex;
        private int trialIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(phase, other.phase)
                && Objects.equals(blockIndex, other.blockIndex)
                && Objects.equals(trialIndex, other.trialIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, phase, blockIndex, trialIndex);
        }
    }
}
