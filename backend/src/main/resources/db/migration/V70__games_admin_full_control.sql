-- Extends the games-owned admin control plane with explicit settings/modifier
-- version streams. Existing V65 remains immutable.

ALTER TABLE games.admin_configurations
    ADD COLUMN configuration_kind VARCHAR(16) NOT NULL DEFAULT 'SETTINGS';

ALTER TABLE games.admin_configurations
    ADD CONSTRAINT ck_admin_config_kind
        CHECK (configuration_kind IN ('SETTINGS', 'MODIFIERS'));

ALTER TABLE games.admin_configurations
    DROP CONSTRAINT ux_admin_config_game_version;

ALTER TABLE games.admin_configurations
    ADD CONSTRAINT ux_admin_config_game_kind_version
        UNIQUE (game_type, configuration_kind, version);

DROP INDEX games.ux_admin_config_one_published_version;

CREATE UNIQUE INDEX ux_admin_config_one_published_version
    ON games.admin_configurations (game_type, configuration_kind)
    WHERE status = 'PUBLISHED';

CREATE UNIQUE INDEX ux_admin_question_one_published_code
    ON games.admin_questions (content_type, external_code)
    WHERE status = 'PUBLISHED';
