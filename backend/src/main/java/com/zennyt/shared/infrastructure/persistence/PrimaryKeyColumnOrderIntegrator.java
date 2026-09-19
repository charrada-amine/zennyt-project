package com.zennyt.shared.infrastructure.persistence;

import org.hibernate.boot.Metadata;
import org.hibernate.boot.model.relational.Namespace;
import org.hibernate.boot.spi.BootstrapContext;
import org.hibernate.boot.spi.MetadataImplementor;
import org.hibernate.engine.spi.SessionFactoryImplementor;
import org.hibernate.integrator.spi.Integrator;
import org.hibernate.mapping.Table;
import org.hibernate.service.spi.SessionFactoryServiceRegistry;

/**
 * Fixe l'ordre des colonnes des clés primaires composites avant que Hibernate ne crée
 * les tables.
 *
 * <p>Hibernate trie les attributs d'une clé composite ({@code @IdClass}) par nom : la clé
 * de {@code games.bart_pumps} deviendrait {@code (balloon_index, pump_index, session_id)}
 * au lieu de {@code (session_id, balloon_index, pump_index)}. L'ordre compte — c'est
 * celui de l'index de la clé primaire, et celui des clés étrangères composites qui la
 * visent. Les entités concernées déclarent donc une {@code @UniqueConstraint} portant
 * exactement les colonnes de la clé, dans l'ordre voulu, et nommée comme elle : Hibernate
 * la fusionne dans la clé primaire et en reprend l'ordre.
 *
 * <p>Deux étapes de Hibernate font ce travail, et aucune n'a lieu d'elle-même en
 * {@code ddl-auto: update} :
 * <ol>
 *   <li>la fusion de la contrainte dans la clé, faite à la première lecture des
 *       contraintes d'unicité de la table — en {@code update}, seulement après la création
 *       des tables ;</li>
 *   <li>le réordonnancement des colonnes ({@link MetadataImplementor#orderColumns}),
 *       réservé par Hibernate aux actions {@code create}.</li>
 * </ol>
 * Cet intégrateur, appelé pendant la construction de la SessionFactory — avant la mise à
 * jour du schéma —, déclenche les deux : une table créée par {@code update} est
 * identique à celle que produirait {@code create}. Les tables existantes ne sont pas
 * concernées, {@code update} ne les recrée pas.
 *
 * <p>Enregistré par {@code META-INF/services/org.hibernate.integrator.spi.Integrator}.
 */
public class PrimaryKeyColumnOrderIntegrator implements Integrator {

    @Override
    public void integrate(Metadata metadata, BootstrapContext bootstrapContext,
                          SessionFactoryImplementor sessionFactory) {
        for (Namespace namespace : metadata.getDatabase().getNamespaces()) {
            for (Table table : namespace.getTables()) {
                table.getUniqueKeys();
            }
        }
        ((MetadataImplementor) metadata).orderColumns(true);
    }

    @Override
    public void disintegrate(SessionFactoryImplementor sessionFactory,
                             SessionFactoryServiceRegistry serviceRegistry) {
        // Rien à défaire.
    }
}
