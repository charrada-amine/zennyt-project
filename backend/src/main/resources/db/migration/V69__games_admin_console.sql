-- Games admin console: versioned editorial content, rotations, non-scoring
-- configuration, assets and immutable audit. Existing scoring tables and rules
-- are deliberately untouched.

CREATE TABLE games.admin_questions (
    id              UUID         PRIMARY KEY,
    external_code   VARCHAR(64)  NOT NULL,
    content_type    VARCHAR(32)  NOT NULL,
    prompt          TEXT         NOT NULL,
    payload         JSONB        NOT NULL DEFAULT '{}'::jsonb,
    status          VARCHAR(16)  NOT NULL DEFAULT 'DRAFT',
    source_id       UUID,
    created_by      UUID         NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ux_admin_questions_code_version UNIQUE (external_code, id),
    CONSTRAINT ck_admin_questions_type CHECK (
        content_type IN ('DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE')),
    CONSTRAINT ck_admin_questions_status CHECK (
        status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_admin_questions_prompt CHECK (length(trim(prompt)) > 0)
);

CREATE INDEX ix_admin_questions_filter
    ON games.admin_questions (content_type, status, updated_at DESC);

CREATE TABLE games.admin_banks (
    id               UUID         PRIMARY KEY,
    code             VARCHAR(64)  NOT NULL,
    name             VARCHAR(120) NOT NULL,
    content_type     VARCHAR(32)  NOT NULL,
    version          INT          NOT NULL,
    rotation_weight  INT          NOT NULL DEFAULT 0,
    status           VARCHAR(16)  NOT NULL DEFAULT 'DRAFT',
    published_at     TIMESTAMPTZ,
    created_by       UUID         NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ux_admin_banks_code_version UNIQUE (code, version),
    CONSTRAINT ck_admin_banks_type CHECK (
        content_type IN ('DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE')),
    CONSTRAINT ck_admin_banks_status CHECK (
        status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_admin_banks_weight CHECK (rotation_weight BETWEEN 0 AND 100),
    CONSTRAINT ck_admin_banks_version CHECK (version >= 1)
);

CREATE TABLE games.admin_bank_items (
    bank_id       UUID NOT NULL REFERENCES games.admin_banks(id) ON DELETE CASCADE,
    content_id    UUID NOT NULL,
    position      INT  NOT NULL,
    PRIMARY KEY (bank_id, content_id),
    CONSTRAINT ux_admin_bank_item_position UNIQUE (bank_id, position),
    CONSTRAINT ck_admin_bank_item_position CHECK (position >= 1)
);

CREATE UNIQUE INDEX ux_admin_bank_one_published_version
    ON games.admin_banks (code) WHERE status = 'PUBLISHED';

CREATE TABLE games.admin_configurations (
    id               UUID         PRIMARY KEY,
    game_type        VARCHAR(48)  NOT NULL,
    version          INT          NOT NULL,
    values_json      JSONB        NOT NULL,
    status           VARCHAR(16)  NOT NULL DEFAULT 'DRAFT',
    published_at     TIMESTAMPTZ,
    created_by       UUID         NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ux_admin_config_game_version UNIQUE (game_type, version),
    CONSTRAINT ck_admin_config_status CHECK (
        status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_admin_config_version CHECK (version >= 1)
);

CREATE UNIQUE INDEX ux_admin_config_one_published_version
    ON games.admin_configurations (game_type) WHERE status = 'PUBLISHED';

CREATE TABLE games.admin_assets (
    id               UUID         PRIMARY KEY,
    game_type        VARCHAR(48)  NOT NULL,
    filename         VARCHAR(255) NOT NULL,
    media_type       VARCHAR(8)   NOT NULL,
    url              TEXT         NOT NULL,
    public_id        TEXT         NOT NULL,
    alt_text         TEXT         NOT NULL,
    status           VARCHAR(16)  NOT NULL DEFAULT 'DRAFT',
    created_by       UUID         NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_admin_assets_media_type CHECK (media_type IN ('PNG', 'SVG')),
    CONSTRAINT ck_admin_assets_status CHECK (
        status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_admin_assets_alt_text CHECK (length(trim(alt_text)) > 0)
);

CREATE TABLE games.admin_audit_log (
    id           UUID         PRIMARY KEY,
    action       VARCHAR(48)  NOT NULL,
    entity_type  VARCHAR(48)  NOT NULL,
    entity_id    UUID         NOT NULL,
    actor_id     UUID         NOT NULL,
    details      JSONB        NOT NULL DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX ix_admin_audit_created_at
    ON games.admin_audit_log (created_at DESC);

-- Existing production catalog snapshots become visible to the admin console.
-- Their IDs point to the authoritative gameplay tables, without duplicating
-- correction data or changing any score.
INSERT INTO games.admin_banks
    (id, code, name, content_type, version, rotation_weight, status,
     published_at, created_by)
VALUES
    ('81000000-0000-0000-0000-000000000001', 'DECISION_FORM_A',
     'Je Décide · Forme A', 'DECISION_SCENARIO', 1, 100, 'PUBLISHED', now(),
     '00000000-0000-0000-0000-000000000000'),
    ('81000000-0000-0000-0000-000000000002', 'EMOTIONAL_RADAR_CORE',
     'Radar émotionnel · Core', 'EMOTIONAL_RADAR_SCENE', 1, 100, 'PUBLISHED', now(),
     '00000000-0000-0000-0000-000000000000');

INSERT INTO games.admin_bank_items (bank_id, content_id, position)
SELECT '81000000-0000-0000-0000-000000000001', scenario_id, position
FROM games.decision_form_items
WHERE form_code = 'A';

INSERT INTO games.admin_bank_items (bank_id, content_id, position)
SELECT '81000000-0000-0000-0000-000000000002', id, scene_order
FROM games.emotional_radar_scenes
WHERE active = TRUE;
