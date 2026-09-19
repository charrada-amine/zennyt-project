package com.zennyt.architecture;

import org.junit.jupiter.api.Test;
import org.springframework.util.ClassUtils;

import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le schéma est généré par Hibernate depuis les entités JPA : il n'y a plus de migrations.
 *
 * <p>Une branche ouverte avant l'abandon de Flyway peut encore apporter un fichier
 * {@code V87__….sql} au merge. Il ne serait jamais exécuté, sans erreur ni avertissement.
 * Ce test le refuse : le changement doit être porté sur les entités — ou, pour ce que JPA
 * n'exprime pas, dans {@code db/schema-complements.sql} et {@code db/reference-data.sql}.
 */
class NoSchemaMigrationsTest {

    @Test
    void aucuneMigrationFlywayNeSubsiste() {
        assertThat(Path.of("src/main/resources/db/migration"))
            .as("Flyway a été retiré : porter ce changement de schéma sur les entités JPA")
            .doesNotExist();
    }

    @Test
    void flywayNEstPlusSurLeClasspath() {
        assertThat(ClassUtils.isPresent("org.flywaydb.core.Flyway", null))
            .as("Flyway recréerait flyway_schema_history et concurrencerait Hibernate")
            .isFalse();
    }
}
