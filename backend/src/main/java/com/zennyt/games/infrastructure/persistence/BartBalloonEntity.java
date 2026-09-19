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
 * Définition JPA de la table {@code games.bart_balloons}.
 *
 * <p>Les lectures et écritures passent par {@link DecisionBehavioralMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "bart_balloons", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans bart_balloons_pkey).
    uniqueConstraints = @UniqueConstraint(name = "bart_balloons_pkey", columnNames = {"session_id", "balloon_index"}))
@Check(name = "ck_bart_balloon_identity", constraints = "phase = 'PRACTICE' AND balloon_index >= 0 AND balloon_index <= 1 OR phase = 'TEST' AND balloon_index >= 2 AND balloon_index <= 31")
@Check(name = "ck_bart_balloon_outcome", constraints = "explosion_point >= 1 AND explosion_point <= 128 AND (outcome = 'EXPLODED' AND pump_count = explosion_point AND earned_points = 0 AND collect_timestamp_ms IS NULL OR outcome = 'COLLECTED' AND pump_count >= 0 AND pump_count <= (explosion_point - 1) AND earned_points >= 0 AND collect_timestamp_ms >= 0)")
@IdClass(BartBalloonEntity.Key.class)
class BartBalloonEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "balloon_index", nullable = false)
    private int balloonIndex;

    @Column(name = "phase", nullable = false, length = 16)
    private String phase;

    @Column(name = "explosion_point", nullable = false)
    private int explosionPoint;

    @Column(name = "pump_count", nullable = false)
    private int pumpCount;

    @Column(name = "outcome", nullable = false, length = 16)
    private String outcome;

    @Column(name = "earned_points", nullable = false)
    private int earnedPoints;

    @Column(name = "collect_timestamp_ms")
    private Long collectTimestampMs;

    /** Clé étrangère {@code games.bart_runs(session_id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "bart_balloons_session_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private BartRunEntity bartRun;

    protected BartBalloonEntity() {
    }

    /** Clé primaire composite (session_id, balloon_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int balloonIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(balloonIndex, other.balloonIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, balloonIndex);
        }
    }
}
