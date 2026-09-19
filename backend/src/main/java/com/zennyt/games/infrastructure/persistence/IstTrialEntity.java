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
 * Définition JPA de la table {@code games.ist_trials}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "ist_trials", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans ist_trials_pkey).
    uniqueConstraints = @UniqueConstraint(name = "ist_trials_pkey", columnNames = {"session_id", "trial_index"}))
@Check(name = "ck_ist_trial_identity", constraints = "phase = 'PRACTICE' AND trial_index >= 0 AND trial_index <= 1 OR phase = 'TEST' AND trial_index >= 2 AND trial_index <= 21")
@Check(name = "ck_ist_trial_values", constraints = "condition IN ('FIXED_WIN', 'DECREASING_WIN') AND majority_color IN ('BLUE', 'ORANGE') AND chosen_color IN ('BLUE', 'ORANGE') AND correct = (majority_color = chosen_color) AND boxes_opened >= 0 AND boxes_opened <= 25 AND blue_seen >= 0 AND orange_seen >= 0 AND (blue_seen + orange_seen) = boxes_opened AND p_correct_at_decision >= 0 AND p_correct_at_decision <= 1 AND decision_timestamp_ms >= 0 AND (confidence IS NULL OR confidence >= 1 AND confidence <= 4)")
@IdClass(IstTrialEntity.Key.class)
class IstTrialEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "trial_index", nullable = false)
    private int trialIndex;

    @Column(name = "phase", nullable = false, length = 16)
    private String phase;

    @Column(name = "condition", nullable = false, length = 16)
    private String condition;

    @Column(name = "majority_color", nullable = false, length = 8)
    private String majorityColor;

    @Column(name = "chosen_color", nullable = false, length = 8)
    private String chosenColor;

    @Column(name = "correct", nullable = false)
    private boolean correct;

    @Column(name = "boxes_opened", nullable = false)
    private int boxesOpened;

    @Column(name = "blue_seen", nullable = false)
    private int blueSeen;

    @Column(name = "orange_seen", nullable = false)
    private int orangeSeen;

    @Column(name = "p_correct_at_decision", nullable = false)
    private double pCorrectAtDecision;

    @Column(name = "trial_points", nullable = false)
    private int trialPoints;

    @Column(name = "decision_timestamp_ms", nullable = false)
    private long decisionTimestampMs;

    @Column(name = "confidence")
    private Integer confidence;

    /** Clé étrangère {@code games.ist_runs(session_id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "ist_trials_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private IstRunEntity istRun;

    protected IstTrialEntity() {
    }

    /** Clé primaire composite (session_id, trial_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int trialIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(trialIndex, other.trialIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, trialIndex);
        }
    }
}
