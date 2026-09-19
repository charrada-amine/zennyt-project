package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.admin_bank_items}.
 *
 * <p>Les lectures et écritures passent par {@link JdbcGameAdminRepository}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "admin_bank_items", schema = "games",
    // La dernière contrainte fixe l'ordre des colonnes de la clé primaire (fusionnée dans admin_bank_items_pkey).
    uniqueConstraints = {
        @UniqueConstraint(name = "ux_admin_bank_item_position", columnNames = {"bank_id", "position"}),
        @UniqueConstraint(name = "admin_bank_items_pkey", columnNames = {"bank_id", "content_id"})})
@Check(name = "ck_admin_bank_item_position", constraints = "position >= 1")
@IdClass(AdminBankItemEntity.Key.class)
class AdminBankItemEntity {

    @Id
    @Column(name = "bank_id", nullable = false)
    private UUID bankId;

    @Id
    @Column(name = "content_id", nullable = false)
    private UUID contentId;

    @Column(name = "position", nullable = false)
    private int position;

    /** Clé étrangère {@code games.admin_banks(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bank_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "admin_bank_items_bank_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private AdminBankEntity adminBank;

    protected AdminBankItemEntity() {
    }

    /** Clé primaire composite (bank_id, content_id). */
    public static class Key implements Serializable {
        private UUID bankId;
        private UUID contentId;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(bankId, other.bankId)
                && Objects.equals(contentId, other.contentId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(bankId, contentId);
        }
    }
}
