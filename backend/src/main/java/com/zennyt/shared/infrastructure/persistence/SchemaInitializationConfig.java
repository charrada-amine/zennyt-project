package com.zennyt.shared.infrastructure.persistence;

import org.springframework.boot.autoconfigure.orm.jpa.EntityManagerFactoryDependsOnPostProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

/**
 * Ordre de démarrage de la base, qui remplace les migrations Flyway :
 *
 * <ol>
 *   <li>{@link DatabaseSchemaLock} — verrou entre instances, refus d'une base Flyway
 *       inachevée ;</li>
 *   <li>Hibernate — crée ou complète le schéma depuis les entités JPA
 *       ({@code ddl-auto: update}, dialecte {@link ZennytPostgreSQLDialect}) ;</li>
 *   <li>{@link SchemaComplementsInitializer} — objets que JPA n'exprime pas, puis données
 *       de référence ; rend le verrou.</li>
 * </ol>
 */
@Configuration(proxyBeanMethods = false)
public class SchemaInitializationConfig {

    @Bean
    DatabaseSchemaLock databaseSchemaLock(DataSource dataSource) {
        return new DatabaseSchemaLock(dataSource);
    }

    /** Le verrou et le garde-fou passent avant que Hibernate ne touche au schéma. */
    @Bean
    static EntityManagerFactoryDependsOnPostProcessor entityManagerFactoryDependsOnSchemaLock() {
        return new EntityManagerFactoryDependsOnPostProcessor(DatabaseSchemaLock.class);
    }

    @Bean
    SchemaComplementsInitializer schemaComplementsInitializer(DataSource dataSource,
                                                              DatabaseSchemaLock lock) {
        return new SchemaComplementsInitializer(dataSource, lock);
    }
}
