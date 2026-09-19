package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_audit_log}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "admin_audit_log", schema = "games",
    indexes = @Index(name = "ix_admin_audit_created_at", columnList = "created_at DESC"))
class AdminAuditLogEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "action", nullable = false, length = 48)
    private String action;

    @Column(name = "entity_type", nullable = false, length = 48)
    private String entityType;

    @Column(name = "entity_id", nullable = false)
    private UUID entityId;

    @Column(name = "actor_id", nullable = false)
    private UUID actorId;

    @ColumnDefault("'{}'::jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "details", nullable = false)
    private String details;

    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected AdminAuditLogEntity() {
    }
}
