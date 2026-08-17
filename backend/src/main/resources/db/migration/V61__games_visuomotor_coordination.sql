-- ⚠️ Renumérotée depuis V28 — NE PAS remettre un numéro inférieur à V51.
--
-- Deux raisons. (1) V28 est déjà pris par une migration de `main`
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

-- V28 — « Je coordonne » : tracking visuomoteur sur carré fixe horaire.
--
-- Les positions pointeur brutes sont persistées pour audit. Le serveur
-- reconstruit la balle et toutes les métriques ; une capture invalide ne crée
-- aucun Attempt ni GameResultRecordedEvent et peut être remplacée par un retry.

ALTER TABLE games.game_sessions DROP CONSTRAINT IF EXISTS ck_game_sessions_type;
ALTER TABLE games.game_sessions ADD CONSTRAINT ck_game_sessions_type
    CHECK (game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',
                         'EMOTIONAL_REGULATION', 'CONTINUOUS_ATTENTION',
                         'VISUOMOTOR_COORDINATION'));

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE',
                         'CONTINUOUS_ATTENTION_CORE',
                         'COORDINATION_TRACKING_CORE'));

CREATE TABLE games.coordination_tracking_runs (
    session_id                    UUID             PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    protocol_version              VARCHAR(32)      NOT NULL,
    input_source                  VARCHAR(16)      NOT NULL,
    session_completed             BOOLEAN          NOT NULL,
    interrupted                   BOOLEAN          NOT NULL,
    background_event_count        INT              NOT NULL,
    dropped_frame_count           INT              NOT NULL,
    session_valid                 BOOLEAN          NOT NULL,
    provisional_accuracy_score    INT              NOT NULL,
    overall_accuracy_percent      DOUBLE PRECISION NOT NULL,
    fast_accuracy_percent         DOUBLE PRECISION NOT NULL,
    slow_accuracy_percent         DOUBLE PRECISION NOT NULL,
    long_accuracy_percent         DOUBLE PRECISION NOT NULL,
    short_accuracy_percent        DOUBLE PRECISION NOT NULL,
    average_center_distance       DOUBLE PRECISION NOT NULL,
    test_execution_time_ms        BIGINT           NOT NULL,
    accuracy_valid                BOOLEAN          NOT NULL,
    execution_time_valid          BOOLEAN          NOT NULL,
    task_valid                    BOOLEAN          NOT NULL,
    technical_valid               BOOLEAN          NOT NULL,
    sample_count                  INT              NOT NULL,
    absent_sample_count           INT              NOT NULL,
    timing_deviation_count        INT              NOT NULL,
    sampling_gap_count            INT              NOT NULL,
    validity_issues               TEXT             NOT NULL,
    recorded_at                   TIMESTAMPTZ      NOT NULL DEFAULT now(),
    CONSTRAINT ck_coord_protocol CHECK (
        protocol_version = 'FIXED_SQUARE_CW_V1'),
    CONSTRAINT ck_coord_input_source CHECK (
        input_source IN ('MOUSE', 'TOUCH', 'STYLUS')),
    CONSTRAINT ck_coord_accuracy_ranges CHECK (
        provisional_accuracy_score BETWEEN 0 AND 100
        AND overall_accuracy_percent BETWEEN 0 AND 100
        AND fast_accuracy_percent BETWEEN 0 AND 100
        AND slow_accuracy_percent BETWEEN 0 AND 100
        AND long_accuracy_percent BETWEEN 0 AND 100
        AND short_accuracy_percent BETWEEN 0 AND 100
        AND average_center_distance BETWEEN 0 AND 1200),
    CONSTRAINT ck_coord_run_counts CHECK (
        background_event_count >= 0
        AND dropped_frame_count >= 0
        AND test_execution_time_ms > 0
        AND sample_count >= 0
        AND absent_sample_count >= 0
        AND absent_sample_count <= sample_count
        AND timing_deviation_count >= 0
        AND sampling_gap_count >= 0),
    CONSTRAINT ck_coord_task_valid CHECK (
        task_valid = (accuracy_valid AND execution_time_valid)),
    CONSTRAINT ck_coord_technical_valid CHECK (
        technical_valid = (
            session_completed AND NOT interrupted AND background_event_count = 0
            AND timing_deviation_count = 0)),
    CONSTRAINT ck_coord_session_valid CHECK (
        session_valid = (technical_valid AND task_valid))
);

CREATE TABLE games.coordination_tracking_segments (
    session_id          UUID        NOT NULL
        REFERENCES games.coordination_tracking_runs(session_id) ON DELETE CASCADE,
    segment_index       INT         NOT NULL,
    phase               VARCHAR(16) NOT NULL,
    speed               VARCHAR(8)  NOT NULL,
    nominal_duration_ms INT         NOT NULL,
    actual_start_ms     BIGINT      NOT NULL,
    actual_end_ms       BIGINT      NOT NULL,
    PRIMARY KEY (session_id, segment_index),
    CONSTRAINT ck_coord_segment_index CHECK (segment_index BETWEEN 1 AND 14),
    CONSTRAINT ck_coord_segment_phase CHECK (
        (phase = 'PRACTICE' AND segment_index BETWEEN 1 AND 2)
        OR (phase = 'TEST' AND segment_index BETWEEN 3 AND 14)),
    CONSTRAINT ck_coord_segment_speed CHECK (speed IN ('SLOW', 'FAST')),
    CONSTRAINT ck_coord_segment_duration CHECK (
        nominal_duration_ms IN (2333, 7000)
        AND actual_start_ms >= 0
        AND actual_end_ms > actual_start_ms)
);

CREATE TABLE games.coordination_tracking_samples (
    session_id      UUID    NOT NULL,
    segment_index   INT     NOT NULL,
    sample_index    INT     NOT NULL,
    timestamp_ms    BIGINT  NOT NULL,
    pointer_present BOOLEAN NOT NULL,
    pointer_x       INT,
    pointer_y       INT,
    PRIMARY KEY (session_id, segment_index, sample_index),
    FOREIGN KEY (session_id, segment_index)
        REFERENCES games.coordination_tracking_segments(session_id, segment_index)
        ON DELETE CASCADE,
    CONSTRAINT ck_coord_sample_index CHECK (sample_index BETWEEN 1 AND 2000),
    CONSTRAINT ck_coord_sample_timestamp CHECK (timestamp_ms >= 0),
    CONSTRAINT ck_coord_sample_pointer CHECK (
        (pointer_present
            AND pointer_x BETWEEN 0 AND 1000000
            AND pointer_y BETWEEN 0 AND 1000000)
        OR
        (NOT pointer_present AND pointer_x IS NULL AND pointer_y IS NULL))
);

-- Défense DB contre deux résultats valides concurrents pour le même mini-jeu.
CREATE UNIQUE INDEX ux_coord_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'COORDINATION_TRACKING_CORE';
