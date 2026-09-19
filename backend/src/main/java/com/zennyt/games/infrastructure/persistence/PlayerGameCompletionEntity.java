package com.zennyt.games.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Définition JPA de la table {@code games.player_game_completions}.
 *
 * <p>Les lectures et écritures passent par {@link GameCompletionRepositoryAdapter}
 * (SQL direct) : cette entité ne sert qu'à faire de JPA la source du schéma de la
 * table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "player_game_completions", schema = "games",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans player_game_completions_pkey).
    uniqueConstraints = @UniqueConstraint(name = "player_game_completions_pkey", columnNames = {"player_id", "game_key"}))
@Check(name = "ck_player_game_completions_count", constraints = "completion_count >= 1")
@Check(name = "ck_player_game_completions_key", constraints = "game_key IN ('MOVE_FAST', 'CONTINUOUS_ATTENTION', 'COORDINATION_TRACKING', 'MEMORY_QUEST_DIGITS', 'MEMORY_QUEST_IMAGES', 'OBJECT_LOCATION', 'DECISION', 'OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREDICTIVE_PUZZLE', 'EMOTIONAL_RADAR', 'REFLECTIVE_PAUSE', 'STRATEGIC_CHOICES', 'BART', 'INFORMATION_SAMPLING')")
@IdClass(PlayerGameCompletionEntity.Key.class)
class PlayerGameCompletionEntity {

    @Id
    @Column(name = "player_id", nullable = false)
    private UUID playerId;

    @Id
    @Column(name = "game_key", nullable = false, length = 40)
    private String gameKey;

    @Column(name = "first_completed_at", nullable = false)
    private Instant firstCompletedAt;

    @Column(name = "last_completed_at", nullable = false)
    private Instant lastCompletedAt;

    @ColumnDefault("1")
    @Column(name = "completion_count", nullable = false)
    private int completionCount;

    protected PlayerGameCompletionEntity() {
    }

    /** Clé primaire composite (player_id, game_key). */
    public static class Key implements Serializable {
        private UUID playerId;
        private String gameKey;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(playerId, other.playerId)
                && Objects.equals(gameKey, other.gameKey);
        }

        @Override
        public int hashCode() {
            return Objects.hash(playerId, gameKey);
        }
    }
}
