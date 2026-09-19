package com.zennyt.shared.infrastructure.persistence;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.InitializingBean;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Verrou et garde-fou posés AVANT que Hibernate ne touche au schéma.
 *
 * <ol>
 *   <li><b>Un seul démarrage à la fois.</b> Flyway verrouillait la base pendant ses
 *       migrations ; la mise à jour du schéma par Hibernate ne le fait pas. Deux
 *       instances démarrant ensemble sur une base neuve créeraient les mêmes tables en
 *       parallèle et l'une échouerait. Le verrou consultatif pris ici n'est rendu qu'une
 *       fois les compléments SQL et les données de référence appliqués
 *       ({@link SchemaComplementsInitializer}) : la seconde instance trouve alors une
 *       base complète.</li>
 *   <li><b>Refus d'une base Flyway inachevée.</b> Une base migrée par Flyway sans aller
 *       jusqu'à V86 n'a ni les dernières données de référence ni les dernières
 *       évolutions de contraintes, que {@code ddl-auto: update} ne rattrape pas : il
 *       ajoute tables, colonnes et index, il ne modifie jamais l'existant. Mieux vaut
 *       refuser de démarrer que de laisser une telle base à moitié à jour.</li>
 * </ol>
 *
 * <p>Le verrou est transactionnel ({@code pg_advisory_xact_lock}) : il tombe avec la
 * transaction, y compris si le démarrage échoue avant {@link #release()} — le pool
 * annule toute transaction restée ouverte sur une connexion qu'on lui rend.
 */
public class DatabaseSchemaLock implements InitializingBean, DisposableBean {

    /** Clé du verrou consultatif, propre à l'application ("zennyt" en ASCII). */
    static final long LOCK_KEY = 0x7a656e6e7974L;

    /** Dernière migration Flyway : le schéma JPA en est la reproduction exacte. */
    static final String LAST_FLYWAY_VERSION = "86";

    private static final Logger log = LoggerFactory.getLogger(DatabaseSchemaLock.class);

    private final DataSource dataSource;
    private Connection connection;

    public DatabaseSchemaLock(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void afterPropertiesSet() throws SQLException {
        Connection c = dataSource.getConnection();
        try {
            c.setAutoCommit(false);
            if (!queryBoolean(c, "SELECT pg_try_advisory_xact_lock(" + LOCK_KEY + ")")) {
                log.info("Schéma en cours d'initialisation par une autre instance : attente de son verrou");
                try (Statement st = c.createStatement()) {
                    st.execute("SELECT pg_advisory_xact_lock(" + LOCK_KEY + ")");
                }
            }
            requireCompleteFlywayHistory(c);
        } catch (SQLException | RuntimeException e) {
            close(c);
            throw e;
        }
        connection = c;
    }

    private static void requireCompleteFlywayHistory(Connection c) throws SQLException {
        if (!queryBoolean(c, "SELECT to_regclass('public.flyway_schema_history') IS NOT NULL")) {
            return;
        }
        boolean complete = queryBoolean(c, """
            SELECT NOT EXISTS (SELECT 1 FROM public.flyway_schema_history WHERE NOT success)
               AND EXISTS (SELECT 1 FROM public.flyway_schema_history
                            WHERE version = '%s' AND success)""".formatted(LAST_FLYWAY_VERSION));
        if (!complete) {
            throw new IllegalStateException(("Base migrée par Flyway sans aller jusqu'à V%1$s, ou avec une"
                + " migration en échec (public.flyway_schema_history). Le schéma est désormais généré par"
                + " Hibernate, qui ne rattrape ni les données de référence ni les contraintes modifiées par"
                + " les migrations manquantes. Démarrer une fois la dernière version du backend gérée par"
                + " Flyway (V%1$s) pour terminer ses migrations, puis cette version ; en développement,"
                + " on peut aussi recréer la base.").formatted(LAST_FLYWAY_VERSION));
        }
    }

    private static boolean queryBoolean(Connection c, String sql) throws SQLException {
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getBoolean(1);
        }
    }

    /** Rend le verrou : le schéma est complet et les données de référence sont en place. */
    void release() {
        Connection c = connection;
        connection = null;
        if (c != null) {
            close(c);
        }
    }

    @Override
    public void destroy() {
        release();
    }

    private static void close(Connection c) {
        try {
            c.rollback();
        } catch (SQLException e) {
            log.warn("Annulation de la transaction du verrou de schéma impossible", e);
        }
        try {
            c.close();
        } catch (SQLException e) {
            log.warn("Fermeture de la connexion du verrou de schéma impossible", e);
        }
    }
}
