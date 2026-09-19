package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_assets}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "admin_assets", schema = "games")
@Check(name = "ck_admin_assets_alt_text", constraints = "length(trim(alt_text)) > 0")
@Check(name = "ck_admin_assets_media_type", constraints = "media_type IN ('PNG', 'SVG')")
@Check(name = "ck_admin_assets_status", constraints = "status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')")
class AdminAssetEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "game_type", nullable = false, length = 48)
    private String gameType;

    @Column(name = "filename", nullable = false)
    private String filename;

    @Column(name = "media_type", nullable = false, length = 8)
    private String mediaType;

    @Column(name = "url", nullable = false, length = Length.LONG32)
    private String url;

    @Column(name = "public_id", nullable = false, length = Length.LONG32)
    private String publicId;

    @Column(name = "alt_text", nullable = false, length = Length.LONG32)
    private String altText;

    @ColumnDefault("'DRAFT'")
    @Column(name = "status", nullable = false, length = 16)
    private String status;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @ColumnDefault("now()")
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AdminAssetEntity() {
    }
}
