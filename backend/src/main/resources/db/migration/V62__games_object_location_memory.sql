-- ⚠️ Renumérotée depuis V29 — NE PAS remettre un numéro inférieur à V51.
--
-- Deux raisons. (1) V29 est déjà pris par une migration de `main`
-- (job_offer_position / drop_match_job_offer_title / experience_level_rename) :
-- la collision empêchait Flyway de démarrer (« Found more than one migration
-- with version »), donc le backend entier refusait de booter.
-- (2) Cette migration réécrit `ck_game_attempts_mini_game` et
-- `ck_game_sessions_type` avec la liste CUMULATIVE de tous les mini-jeux
-- connus, Emotional Radar (V50) et Reflective Pause (V51) compris. Placée
-- AVANT eux, elle était écrasée par leurs listes plus courtes : sur une base
-- migrée à neuf, CONTINUOUS_ATTENTION_CORE, COORDINATION_TRACKING_CORE et
-- OBJECT_LOCATION_BINDING_CORE disparaissaient de la contrainte et toute
-- soumission de ces jeux était rejetée. La dernière migration à réécrire ces
-- contraintes doit porter la liste la plus complète.

-- V29 — « Je place » : mémoire visuospatiale et liaison objet-position.
--
-- Le client persiste uniquement timings et actions. Objets, origines, réserve,
-- catégories d'erreur et score sont reconstruits depuis l'UUID de session.
-- Un run techniquement invalide reste audit-only et peut être remplacé.

ALTER TABLE games.game_sessions DROP CONSTRAINT IF EXISTS ck_game_sessions_type;
ALTER TABLE games.game_sessions ADD CONSTRAINT ck_game_sessions_type
    CHECK (game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',
                         'EMOTIONAL_REGULATION', 'CONTINUOUS_ATTENTION',
                         'VISUOMOTOR_COORDINATION', 'VISUOSPATIAL_MEMORY'));

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE',
                         'CONTINUOUS_ATTENTION_CORE',
                         'COORDINATION_TRACKING_CORE',
                         'OBJECT_LOCATION_BINDING_CORE'));

CREATE TABLE games.object_location_runs (
    session_id                          UUID             PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    protocol_version                    VARCHAR(40)      NOT NULL,
    completion_reason                   VARCHAR(32)      NOT NULL,
    session_completed                   BOOLEAN          NOT NULL,
    interrupted                         BOOLEAN          NOT NULL,
    background_event_count              INT              NOT NULL,
    focus_loss_count                    INT              NOT NULL,
    orientation_change_count            INT              NOT NULL,
    dropped_frame_count                 INT              NOT NULL,
    session_valid                       BOOLEAN          NOT NULL,
    technical_valid                     BOOLEAN          NOT NULL,
    minimum_levels_valid                BOOLEAN          NOT NULL,
    progression_valid                   BOOLEAN          NOT NULL,
    timing_valid                        BOOLEAN          NOT NULL,
    provisional_accuracy_score          INT              NOT NULL,
    completed_level_count               INT              NOT NULL,
    passed_level_count                  INT              NOT NULL,
    administered_object_count           INT              NOT NULL,
    exact_placement_count               INT              NOT NULL,
    swap_count                          INT              NOT NULL,
    local_error_count                   INT              NOT NULL,
    global_error_count                  INT              NOT NULL,
    unplaced_count                      INT              NOT NULL,
    exact_accuracy_percent              DOUBLE PRECISION NOT NULL,
    swap_rate_percent                   DOUBLE PRECISION NOT NULL,
    local_error_rate_percent            DOUBLE PRECISION NOT NULL,
    global_error_rate_percent           DOUBLE PRECISION NOT NULL,
    average_displacement_cells          DOUBLE PRECISION NOT NULL,
    span                                INT              NOT NULL,
    load_slope                          DOUBLE PRECISION,
    average_first_placement_interval_ms DOUBLE PRECISION,
    reposition_count                    INT              NOT NULL,
    timing_deviation_count              INT              NOT NULL,
    validity_issues                     TEXT             NOT NULL,
    recorded_at                         TIMESTAMPTZ      NOT NULL DEFAULT now(),
    CONSTRAINT ck_object_location_protocol CHECK (
        protocol_version = 'OBJECT_LOCATION_FINE_V1'),
    CONSTRAINT ck_object_location_completion CHECK (
        (completion_reason IN ('MAX_LEVELS', 'STOP_RULE') AND session_completed)
        OR (completion_reason = 'TECHNICAL_INTERRUPTION' AND NOT session_completed)),
    CONSTRAINT ck_object_location_technical_counts CHECK (
        background_event_count >= 0 AND focus_loss_count >= 0
        AND orientation_change_count >= 0 AND dropped_frame_count >= 0
        AND reposition_count >= 0 AND timing_deviation_count >= 0),
    CONSTRAINT ck_object_location_level_counts CHECK (
        completed_level_count BETWEEN 0 AND 6
        AND passed_level_count BETWEEN 0 AND completed_level_count
        AND administered_object_count BETWEEN 0 AND 33),
    CONSTRAINT ck_object_location_classification CHECK (
        exact_placement_count >= 0 AND swap_count >= 0
        AND local_error_count >= 0 AND global_error_count >= 0
        AND exact_placement_count + swap_count + local_error_count
            + global_error_count + unplaced_count = administered_object_count
        AND unplaced_count >= 0),
    CONSTRAINT ck_object_location_ranges CHECK (
        provisional_accuracy_score BETWEEN 0 AND 100
        AND exact_accuracy_percent BETWEEN 0 AND 100
        AND swap_rate_percent BETWEEN 0 AND 100
        AND local_error_rate_percent BETWEEN 0 AND 100
        AND global_error_rate_percent BETWEEN 0 AND 100
        AND average_displacement_cells BETWEEN 0 AND sqrt(18::DOUBLE PRECISION)
        AND span BETWEEN 0 AND 8
        AND (average_first_placement_interval_ms IS NULL
            OR average_first_placement_interval_ms >= 0)),
    CONSTRAINT ck_object_location_timing_valid CHECK (
        timing_valid = (timing_deviation_count = 0)),
    CONSTRAINT ck_object_location_minimum_levels CHECK (
        minimum_levels_valid = (completed_level_count >= 3)),
    CONSTRAINT ck_object_location_technical_valid CHECK (
        technical_valid = (
            session_completed AND NOT interrupted
            AND background_event_count = 0 AND focus_loss_count = 0
            AND orientation_change_count = 0 AND timing_valid)),
    CONSTRAINT ck_object_location_session_valid CHECK (
        session_valid = (
            technical_valid AND minimum_levels_valid AND progression_valid))
);

CREATE TABLE games.object_location_levels (
    session_id                          UUID             NOT NULL
        REFERENCES games.object_location_runs(session_id) ON DELETE CASCADE,
    level_index                        INT              NOT NULL,
    phase                              VARCHAR(16)      NOT NULL,
    object_count                       INT              NOT NULL,
    actual_encoding_duration_ms        INT              NOT NULL,
    actual_retention_duration_ms       INT              NOT NULL,
    actual_recall_duration_ms          INT              NOT NULL,
    timed_out                          BOOLEAN          NOT NULL,
    completed                          BOOLEAN          NOT NULL,
    passed                             BOOLEAN          NOT NULL,
    exact_count                        INT              NOT NULL,
    swap_count                         INT              NOT NULL,
    local_error_count                  INT              NOT NULL,
    global_error_count                 INT              NOT NULL,
    unplaced_count                     INT              NOT NULL,
    exact_accuracy_percent             DOUBLE PRECISION NOT NULL,
    average_displacement_cells         DOUBLE PRECISION NOT NULL,
    action_count                       INT              NOT NULL,
    reposition_count                   INT              NOT NULL,
    average_first_placement_interval_ms DOUBLE PRECISION,
    PRIMARY KEY (session_id, level_index),
    CONSTRAINT ck_object_location_level_identity CHECK (
        (phase = 'PRACTICE' AND level_index = 0 AND object_count = 2)
        OR (phase = 'TEST' AND level_index BETWEEN 1 AND 6
            AND object_count = level_index + 2)),
    CONSTRAINT ck_object_location_level_durations CHECK (
        actual_encoding_duration_ms BETWEEN 0 AND object_count * 1500 + 250
        AND actual_retention_duration_ms BETWEEN 0 AND 2250
        AND actual_recall_duration_ms BETWEEN 0 AND object_count * 4000 + 250),
    CONSTRAINT ck_object_location_level_completion CHECK (
        NOT timed_out OR completed),
    CONSTRAINT ck_object_location_level_categories CHECK (
        exact_count >= 0 AND swap_count >= 0 AND local_error_count >= 0
        AND global_error_count >= 0
        AND exact_count + swap_count + local_error_count + global_error_count
            + unplaced_count
            = object_count
        AND unplaced_count >= 0
        AND exact_accuracy_percent BETWEEN 0 AND 100
        AND average_displacement_cells BETWEEN 0 AND sqrt(18::DOUBLE PRECISION)),
    CONSTRAINT ck_object_location_level_actions CHECK (
        action_count BETWEEN 0 AND 256 AND reposition_count >= 0
        AND (average_first_placement_interval_ms IS NULL
            OR average_first_placement_interval_ms >= 0))
);

CREATE TABLE games.object_location_actions (
    session_id       UUID        NOT NULL,
    level_index      INT         NOT NULL,
    action_index     INT         NOT NULL,
    action_type      VARCHAR(24) NOT NULL,
    object_id        VARCHAR(48) NOT NULL,
    target_cell_index INT,
    timestamp_ms     BIGINT      NOT NULL,
    PRIMARY KEY (session_id, level_index, action_index),
    FOREIGN KEY (session_id, level_index)
        REFERENCES games.object_location_levels(session_id, level_index)
        ON DELETE CASCADE,
    CONSTRAINT ck_object_location_action_index CHECK (
        action_index BETWEEN 1 AND 256),
    CONSTRAINT ck_object_location_action_type CHECK (
        (action_type = 'PLACE' AND target_cell_index IS NOT NULL
            AND target_cell_index BETWEEN 0 AND 15)
        OR (action_type = 'RETURN_TO_RESERVE' AND target_cell_index IS NULL)),
    CONSTRAINT ck_object_location_action_object CHECK (
        object_id IN (
            'SMARTPHONE', 'WIRELESS_EARBUDS', 'SMARTWATCH', 'REUSABLE_BOTTLE',
            'INSTANT_CAMERA', 'SNEAKER', 'SUCCULENT', 'CERAMIC_MUG', 'BACKPACK',
            'GAME_CONTROLLER', 'BICYCLE_HELMET', 'DESK_LAMP', 'NOTEBOOK',
            'SUNGLASSES', 'KEYCARD', 'COMPACT_DRONE', 'PORTABLE_SPEAKER',
            'POWER_BANK', 'STYLUS_TABLET', 'TRAVEL_POUCH')),
    CONSTRAINT ck_object_location_action_timestamp CHECK (timestamp_ms >= 0)
);

-- Défense DB contre deux résultats valides concurrents pour le même mini-jeu.
CREATE UNIQUE INDEX ux_object_location_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'OBJECT_LOCATION_BINDING_CORE';
