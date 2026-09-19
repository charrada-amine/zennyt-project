package com.zennyt.shared.infrastructure.persistence;

import org.springframework.boot.jdbc.init.DataSourceScriptDatabaseInitializer;
import org.springframework.boot.sql.init.DatabaseInitializationMode;
import org.springframework.boot.sql.init.DatabaseInitializationSettings;
import org.springframework.core.io.Resource;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * Complète le schéma généré par Hibernate : applique {@code db/schema-complements.sql}
 * (ce que JPA ne sait pas exprimer) puis {@code db/reference-data.sql} (données de
 * référence, une seule fois par base), et rend le {@link DatabaseSchemaLock}.
 *
 * <p>Branché sur l'initialisation de base de Spring Boot : avec
 * {@code spring.jpa.defer-datasource-initialization}, il s'exécute juste après la
 * création de l'EntityManagerFactory — donc après la mise à jour du schéma — et tout
 * bean qui dépend de l'initialisation de la base (JdbcTemplate…) l'attend.
 *
 * <p>Chaque script part en une seule instruction JDBC, dans une transaction : le pilote
 * PostgreSQL découpe lui-même les requêtes et comprend les blocs {@code $$} des
 * fonctions PL/pgSQL, que le découpage de Spring ({@code ScriptUtils}) mutilerait.
 */
class SchemaComplementsInitializer extends DataSourceScriptDatabaseInitializer {

    static final String SCHEMA_COMPLEMENTS = "classpath:db/schema-complements.sql";
    static final String REFERENCE_DATA = "classpath:db/reference-data.sql";

    private final DatabaseSchemaLock lock;

    SchemaComplementsInitializer(DataSource dataSource, DatabaseSchemaLock lock) {
        super(dataSource, settings());
        this.lock = lock;
    }

    private static DatabaseInitializationSettings settings() {
        DatabaseInitializationSettings settings = new DatabaseInitializationSettings();
        settings.setSchemaLocations(List.of(SCHEMA_COMPLEMENTS));
        settings.setDataLocations(List.of(REFERENCE_DATA));
        settings.setMode(DatabaseInitializationMode.ALWAYS);
        settings.setContinueOnError(false);
        return settings;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        try {
            super.afterPropertiesSet();
        } finally {
            lock.release();
        }
    }

    @Override
    protected void runScripts(Scripts scripts) {
        for (Resource script : scripts) {
            execute(script);
        }
    }

    private void execute(Resource script) {
        String sql;
        try {
            sql = script.getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture impossible : " + script.getDescription(), e);
        }
        try (Connection connection = getDataSource().getConnection()) {
            connection.setAutoCommit(false);
            try (Statement statement = connection.createStatement()) {
                statement.setEscapeProcessing(false);
                statement.execute(sql);
                connection.commit();
            } catch (SQLException | RuntimeException e) {
                connection.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Échec de " + script.getDescription() + " : " + e.getMessage(), e);
        }
    }
}
