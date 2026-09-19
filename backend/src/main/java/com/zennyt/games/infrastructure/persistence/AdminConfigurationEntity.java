package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_configurations}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 *
 * <p>Index non exprimables en JPA, créés par {@code db/schema-complements.sql} :
 * <ul>
 *   <li>{@code ux_admin_config_one_published_version}</li>
 * </ul>
 */
@Entity
@Table(name = "admin_configurations", schema = "games",
    uniqueConstraints = @UniqueConstraint(name = "ux_admin_config_game_kind_version", columnNames = {"game_type", "configuration_kind", "version"}))
@Check(name = "ck_admin_config_kind", constraints = "configuration_kind IN ('SETTINGS', 'MODIFIERS')")
@Check(name = "ck_admin_config_status", constraints = "status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')")
@Check(name = "ck_admin_config_version", constraints = "version >= 1")
class AdminConfigurationEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "game_type", nullable = false, length = 48)
    private String gameType;

    @Column(name = "version", nullable = false)
    private int version;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "values_json", nullable = false)
    private String valuesJson;

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

    @ColumnDefault("'SETTINGS'")
    @Column(name = "configuration_kind", nullable = false, length = 16)
    private String configurationKind;

    protected AdminConfigurationEntity() {
    }
}
