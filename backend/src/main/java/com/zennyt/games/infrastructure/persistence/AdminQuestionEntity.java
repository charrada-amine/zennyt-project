package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_questions}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 *
 * <p>Index non exprimables en JPA, créés par {@code db/schema-complements.sql} :
 * <ul>
 *   <li>{@code ux_admin_question_one_published_code}</li>
 * </ul>
 */
@Entity
@Table(name = "admin_questions", schema = "games",
    uniqueConstraints = @UniqueConstraint(name = "ux_admin_questions_code_version", columnNames = {"external_code", "id"}),
    indexes = @Index(name = "ix_admin_questions_filter", columnList = "content_type, status, updated_at DESC"))
@Check(name = "ck_admin_questions_prompt", constraints = "length(trim(prompt)) > 0")
@Check(name = "ck_admin_questions_status", constraints = "status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')")
@Check(name = "ck_admin_questions_type", constraints = "content_type IN ('DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE')")
class AdminQuestionEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "external_code", nullable = false, length = 64)
    private String externalCode;

    @Column(name = "content_type", nullable = false, length = 32)
    private String contentType;

    @Column(name = "prompt", nullable = false, length = Length.LONG32)
    private String prompt;

    @ColumnDefault("'{}'::jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload", nullable = false)
    private String payload;

    @ColumnDefault("'DRAFT'")
    @Column(name = "status", nullable = false, length = 16)
    private String status;

    @Column(name = "source_id")
    private UUID sourceId;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @ColumnDefault("now()")
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @ColumnDefault("now()")
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AdminQuestionEntity() {
    }
}
