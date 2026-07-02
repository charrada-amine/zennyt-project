CREATE SCHEMA IF NOT EXISTS games;

CREATE TABLE IF NOT EXISTS games.game_sessions (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL,
    game_type VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT ck_game_sessions_type CHECK (
        game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION')
    ),
    CONSTRAINT ck_game_sessions_status CHECK (
        status IN ('IN_PROGRESS', 'COMPLETED', 'ABANDONED')
    )
);

CREATE TABLE IF NOT EXISTS games.game_attempts (
    session_id UUID NOT NULL REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    mini_game VARCHAR(40) NOT NULL,
    raw_points INTEGER NOT NULL,
    max_points INTEGER NOT NULL,
    level VARCHAR(80) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_game_attempts_mini_game CHECK (
        mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE', 'MOVE_FAST_CORE')
    ),
    CONSTRAINT ck_game_attempts_points CHECK (
        raw_points >= 0 AND max_points > 0 AND raw_points <= max_points
    )
);

CREATE INDEX IF NOT EXISTS idx_game_sessions_player
    ON games.game_sessions (player_id);

CREATE INDEX IF NOT EXISTS idx_game_sessions_type_status
    ON games.game_sessions (game_type, status);

CREATE INDEX IF NOT EXISTS idx_game_attempts_session
    ON games.game_attempts (session_id);
