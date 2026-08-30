-- Immutable non-scoring control snapshot captured for every new game session.
-- Existing sessions receive the empty snapshot and retain historical behavior.

ALTER TABLE games.game_sessions
    ADD COLUMN runtime_settings_version INT,
    ADD COLUMN runtime_modifiers_version INT,
    ADD COLUMN runtime_settings TEXT NOT NULL DEFAULT '{}',
    ADD COLUMN runtime_modifiers TEXT NOT NULL DEFAULT '{}';

ALTER TABLE games.game_sessions
    ADD CONSTRAINT ck_game_sessions_runtime_settings_version
        CHECK (runtime_settings_version IS NULL OR runtime_settings_version >= 1),
    ADD CONSTRAINT ck_game_sessions_runtime_modifiers_version
        CHECK (runtime_modifiers_version IS NULL OR runtime_modifiers_version >= 1);
