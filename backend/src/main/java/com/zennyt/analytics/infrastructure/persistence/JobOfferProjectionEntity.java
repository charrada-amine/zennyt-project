package com.zennyt.analytics.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code analytics.job_offer_projection}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcAnalyticsProjectionWriter} et {@link JdbcAnalyticsReadRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "job_offer_projection", schema = "analytics",
    indexes = @Index(name = "idx_analytics_job_offer_recruiter", columnList = "recruiter_id, status"))
class JobOfferProjectionEntity {

    @Id
    @Column(name = "job_offer_id", nullable = false)
    private UUID jobOfferId;

    @Column(name = "recruiter_id", nullable = false)
    private UUID recruiterId;

    @ColumnDefault("'DRAFT'")
    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "posted_at")
    private Instant postedAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected JobOfferProjectionEntity() {
    }
}
