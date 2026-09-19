package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_banks}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 *
 * <p>Index non exprimables en JPA, créés par {@code db/schema-complements.sql} :
 * <ul>
 *   <li>{@code ux_admin_bank_one_published_version}</li>
 * </ul>
 */
@Entity
@Table(name = "admin_banks", schema = "games",
    uniqueConstraints = @UniqueConstraint(name = "ux_admin_banks_code_version", columnNames = {"code", "version"}))
@Check(name = "ck_admin_banks_status", constraints = "status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')")
@Check(name = "ck_admin_banks_type", constraints = "content_type IN ('DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE')")
@Check(name = "ck_admin_banks_version", constraints = "version >= 1")
@Check(name = "ck_admin_banks_weight", constraints = "rotation_weight >= 0 AND rotation_weight <= 100")
class AdminBankEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "code", nullable = false, length = 64)
    private String code;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "content_type", nullable = false, length = 32)
    private String contentType;

    @Column(name = "version", nullable = false)
    private int version;

    @ColumnDefault("0")
    @Column(name = "rotation_weight", nullable = false)
    private int rotationWeight;

    @ColumnDefault("'DRAFT'")
    @Column(name = "status", nullable = false, length = 16)
    private String status;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @ColumnDefault("now()")
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AdminBankEntity() {
    }
}
