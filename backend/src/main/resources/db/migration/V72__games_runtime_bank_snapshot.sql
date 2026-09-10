-- Published question bank selected for a new session. This is a snapshot:
-- later rotation/publication changes do not mutate an in-progress assessment.

ALTER TABLE games.game_sessions
    ADD COLUMN runtime_bank_id UUID,
    ADD COLUMN runtime_bank_code VARCHAR(64),
    ADD COLUMN runtime_bank_version INT,
    ADD COLUMN runtime_bank_content_type VARCHAR(32);

ALTER TABLE games.game_sessions
    ADD CONSTRAINT ck_game_sessions_runtime_bank_version
        CHECK (runtime_bank_version IS NULL OR runtime_bank_version >= 1),
    ADD CONSTRAINT ck_game_sessions_runtime_bank_content_type
        CHECK (runtime_bank_content_type IS NULL OR runtime_bank_content_type IN (
            'DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE'));
