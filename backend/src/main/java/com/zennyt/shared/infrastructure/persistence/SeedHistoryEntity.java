package com.zennyt.shared.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

/**
 * Registre des lots de données de référence appliqués ({@code db/reference-data.sql}).
 *
 * <p>Une ligne par lot. Un lot inscrit ici n'est plus jamais rejoué, même si ses lignes
 * ont été modifiées ou supprimées depuis — le rôle que tenait
 * {@code flyway_schema_history} pour les migrations de données. Écrit uniquement par le
 * script lui-même : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table.
 */
@Entity
@Table(name = "seed_history")
class SeedHistoryEntity {

    @Id
    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @ColumnDefault("now()")
    @Column(name = "applied_at", nullable = false)
    private Instant appliedAt;

    protected SeedHistoryEntity() {
    }
}
