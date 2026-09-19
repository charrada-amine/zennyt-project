package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinColumns;
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
 * Définition JPA de la table {@code games.object_location_actions}.
 *
 * <p>Les lectures et écritures passent par {@link ObjectLocationMetricsRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "object_location_actions", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans object_location_actions_pkey).
    uniqueConstraints = @UniqueConstraint(name = "object_location_actions_pkey", columnNames = {"session_id", "level_index", "action_index"}))
@Check(name = "ck_object_location_action_index", constraints = "action_index >= 1 AND action_index <= 256")
@Check(name = "ck_object_location_action_object", constraints = "object_id IN ('SMARTPHONE', 'WIRELESS_EARBUDS', 'SMARTWATCH', 'REUSABLE_BOTTLE', 'INSTANT_CAMERA', 'SNEAKER', 'SUCCULENT', 'CERAMIC_MUG', 'BACKPACK', 'GAME_CONTROLLER', 'BICYCLE_HELMET', 'DESK_LAMP', 'NOTEBOOK', 'SUNGLASSES', 'KEYCARD', 'COMPACT_DRONE', 'PORTABLE_SPEAKER', 'POWER_BANK', 'STYLUS_TABLET', 'TRAVEL_POUCH')")
@Check(name = "ck_object_location_action_timestamp", constraints = "timestamp_ms >= 0")
@Check(name = "ck_object_location_action_type", constraints = "action_type = 'PLACE' AND target_cell_index IS NOT NULL AND target_cell_index >= 0 AND target_cell_index <= 15 OR action_type = 'RETURN_TO_RESERVE' AND target_cell_index IS NULL")
@IdClass(ObjectLocationActionEntity.Key.class)
class ObjectLocationActionEntity {

    @Id
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Id
    @Column(name = "level_index", nullable = false)
    private int levelIndex;

    @Id
    @Column(name = "action_index", nullable = false)
    private int actionIndex;

    @Column(name = "action_type", nullable = false, length = 24)
    private String actionType;

    @Column(name = "object_id", nullable = false, length = 48)
    private String objectId;

    @Column(name = "target_cell_index")
    private Integer targetCellIndex;

    @Column(name = "timestamp_ms", nullable = false)
    private long timestampMs;

    /** Clé étrangère {@code games.object_location_levels(session_id, level_index) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumns(value = {
        @JoinColumn(name = "session_id", referencedColumnName = "session_id", insertable = false, updatable = false),
        @JoinColumn(name = "level_index", referencedColumnName = "level_index", insertable = false, updatable = false)},
        foreignKey = @ForeignKey(name = "object_location_actions_session_id_level_index_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ObjectLocationLevelEntity objectLocationLevel;

    protected ObjectLocationActionEntity() {
    }

    /** Clé primaire composite (session_id, level_index, action_index). */
    public static class Key implements Serializable {
        private UUID sessionId;
        private int levelIndex;
        private int actionIndex;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(sessionId, other.sessionId)
                && Objects.equals(levelIndex, other.levelIndex)
                && Objects.equals(actionIndex, other.actionIndex);
        }

        @Override
        public int hashCode() {
            return Objects.hash(sessionId, levelIndex, actionIndex);
        }
    }
}
