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
 * Définition JPA de la table {@code games.ist_box_openings}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "ist_box_openings", schema = "games",
    // La dernière contrainte fixe l'ordre des colonnes de la clé primaire (fusionnée dans ist_box_openings_pkey).
    uniqueConstraints = {
        @UniqueConstraint(name = "ist_box_openings_session_id_trial_index_box_index_key", columnNames = {"session_id", "trial_index", "box_index"}),
        @UniqueConstraint(name = "ist_box_openings_pkey", columnNames = {"session_id", "trial_index", "opening_index"})})
@Check(name = "ck_ist_opening", constraints = "opening_index >= 1 AND opening_index <= 25 AND box_index >= 0 AND box_index <= 24 AND timestamp_ms >= 0")
@IdClass(IstBoxOpeningEntity.Key.class)
class IstBoxOpeningEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "trial_index", nullable = false)
    private int trialIndex;

    @Id
    @Column(name = "opening_index", nullable = false)
    private int openingIndex;

    @Column(name = "box_index", nullable = false)
    private int boxIndex;

    @Column(name = "timestamp_ms", nullable = false)
    private long timestampMs;

    /** Clé étrangère {@code games.ist_trials(session_id, trial_index) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumns(value = {
        @JoinColumn(name = "session_id", referencedColumnName = "session_id", insertable = false, updatable = false),
        @JoinColumn(name = "trial_index", referencedColumnName = "trial_index", insertable = false, updatable = false)},
        foreignKey = @ForeignKey(name = "ist_box_openings_session_id_trial_index_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private IstTrialEntity istTrial;

    protected IstBoxOpeningEntity() {
    }

    /** Clé primaire composite (session_id, trial_index, opening_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int trialIndex;
        private int openingIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(trialIndex, other.trialIndex)
                && Objects.equals(openingIndex, other.openingIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, trialIndex, openingIndex);
        }
    }
}
