package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.model.CatalogGame;
import com.zennyt.games.domain.model.GamesProgress;
import com.zennyt.games.domain.repository.GameCompletionRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.EnumMap;
import java.util.Map;
import java.util.UUID;

/**
 * Persistance JDBC de la progression : une ligne par (joueur, jeu), mise à jour
 * à chaque nouvelle partie terminée. Appelée dans la transaction de soumission.
 */
@Component
public class GameCompletionRepositoryAdapter implements GameCompletionRepository {

    static final String UPSERT_SQL = """
        INSERT INTO games.player_game_completions (
            player_id, game_key, first_completed_at, last_completed_at,
            completion_count
        ) VALUES (?, ?, ?, ?, 1)
        ON CONFLICT (player_id, game_key) DO UPDATE SET
            last_completed_at = GREATEST(
                games.player_game_completions.last_completed_at,
                EXCLUDED.last_completed_at),
            completion_count = games.player_game_completions.completion_count + 1
        """;

    static final String SELECT_SQL = """
        SELECT game_key, last_completed_at
        FROM games.player_game_completions
        WHERE player_id = ?
        """;

    private final JdbcTemplate jdbc;

    public GameCompletionRepositoryAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void recordCompletion(UUID playerId, CatalogGame game, Instant completedAt) {
        Timestamp at = Timestamp.from(completedAt);
        jdbc.update(UPSERT_SQL, playerId, game.name(), at, at);
    }

    @Override
    public GamesProgress progressOf(UUID playerId) {
        Map<CatalogGame, Instant> completed = new EnumMap<>(CatalogGame.class);
        jdbc.query(SELECT_SQL, (RowCallbackHandler) rs -> {
            // Une clé inconnue (jeu retiré du catalogue) est ignorée plutôt que
            // de faire échouer toute la lecture de la progression.
            String key = rs.getString("game_key");
            for (CatalogGame game : CatalogGame.values()) {
                if (game.name().equals(key)) {
                    completed.put(game, rs.getTimestamp("last_completed_at").toInstant());
                }
            }
        }, playerId);
        return new GamesProgress(completed);
    }
}
