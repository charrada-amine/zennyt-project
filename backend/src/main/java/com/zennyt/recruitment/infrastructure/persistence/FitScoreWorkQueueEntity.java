package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code recruitment.fitscore_work_queue}.
 *
 * <p>Les lectures et écritures passent par {@link FitScoreWorkQueueRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 *
 * <p>Index non exprimables en JPA, créés par {@code db/schema-complements.sql} :
 * <ul>
 *   <li>{@code idx_fitscore_queue_claim}</li>
 *   <li>{@code uq_fitscore_queue_pending}</li>
 * </ul>
 */
@Entity
@Table(name = "fitscore_work_queue", schema = "recruitment")
@Check(name = "ck_fitscore_queue_priority", constraints = "priority IN (0, 1)")
@Check(name = "ck_fitscore_queue_status", constraints = "status IN ('PENDING', 'DONE', 'FAILED')")
class FitScoreWorkQueueEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "candidate_id", nullable = false)
    private UUID candidateId;

    @Column(name = "job_offer_id", nullable = false)
    private UUID jobOfferId;

    @Column(name = "priority", nullable = false)
    private short priority;

    @Column(name = "status", nullable = false, length = 16)
    private String status;

    @ColumnDefault("0")
    @Column(name = "attempts", nullable = false)
    private short attempts;

    @Column(name = "next_retry_at")
    private Instant nextRetryAt;

    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "last_error", length = Length.LONG32)
    private String lastError;

    protected FitScoreWorkQueueEntity() {
    }
}
