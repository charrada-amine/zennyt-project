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
 * Définition JPA de la table {@code games.bart_pumps}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "bart_pumps", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans bart_pumps_pkey).
    uniqueConstraints = @UniqueConstraint(name = "bart_pumps_pkey", columnNames = {"session_id", "balloon_index", "pump_index"}))
@Check(name = "ck_bart_pump", constraints = "pump_index >= 1 AND pump_index <= 128 AND timestamp_ms >= 0")
@IdClass(BartPumpEntity.Key.class)
class BartPumpEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "balloon_index", nullable = false)
    private int balloonIndex;

    @Id
    @Column(name = "pump_index", nullable = false)
    private int pumpIndex;

    @Column(name = "timestamp_ms", nullable = false)
    private long timestampMs;

    /** Clé étrangère {@code games.bart_balloons(session_id, balloon_index) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumns(value = {
        @JoinColumn(name = "session_id", referencedColumnName = "session_id", insertable = false, updatable = false),
        @JoinColumn(name = "balloon_index", referencedColumnName = "balloon_index", insertable = false, updatable = false)},
        foreignKey = @ForeignKey(name = "bart_pumps_session_id_balloon_index_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private BartBalloonEntity bartBalloon;

    protected BartPumpEntity() {
    }

    /** Clé primaire composite (session_id, balloon_index, pump_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int balloonIndex;
        private int pumpIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(balloonIndex, other.balloonIndex)
                && Objects.equals(pumpIndex, other.pumpIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, balloonIndex, pumpIndex);
        }
    }
}
