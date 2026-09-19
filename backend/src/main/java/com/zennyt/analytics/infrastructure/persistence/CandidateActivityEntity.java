package com.zennyt.analytics.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code analytics.candidate_activity}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcAnalyticsProjectionWriter} et {@link JdbcAnalyticsReadRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "candidate_activity", schema = "analytics",
    indexes = {
        @Index(name = "idx_analytics_candidate_activity_candidate", columnList = "candidate_id"),
        @Index(name = "idx_analytics_candidate_activity_offer", columnList = "job_offer_id")})
@Check(name = "ck_analytics_candidate_activity_kind", constraints = "kind IN ('INTERESTED', 'MATCHED', 'TEST_COMPLETED')")
class CandidateActivityEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "candidate_id", nullable = false)
    private UUID candidateId;

    @Column(name = "job_offer_id", nullable = false)
    private UUID jobOfferId;

    @Column(name = "kind", nullable = false, length = 20)
    private String kind;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    protected CandidateActivityEntity() {
    }
}
