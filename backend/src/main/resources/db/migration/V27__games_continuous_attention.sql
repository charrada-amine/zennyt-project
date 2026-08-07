-- V27 — « Je continue » : Long Rosvold CPT X/AX.
--
-- Le protocole persiste les 1 364 essais bruts pour audit. Une capture
-- techniquement invalide reste dans ces tables mais ne crée aucun Attempt et
-- n'émet aucun GameResultRecordedEvent.

-- 1. Étendre les CHECK existants sans modifier leur historique.
ALTER TABLE games.game_sessions DROP CONSTRAINT IF EXISTS ck_game_sessions_type;
ALTER TABLE games.game_sessions ADD CONSTRAINT ck_game_sessions_type
    CHECK (game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',
                         'EMOTIONAL_REGULATION', 'CONTINUOUS_ATTENTION'));

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE',
                         'CONTINUOUS_ATTENTION_CORE'));

-- 2. Une racine de run par session. Le replace transactionnel permet de
-- remplacer un audit-only invalide par un retry valide, tant qu'aucun Attempt
-- validé n'existe.
CREATE TABLE games.continuous_attention_runs (
    session_id              UUID        PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    protocol_version        VARCHAR(32) NOT NULL,
    session_completed       BOOLEAN     NOT NULL,
    interrupted             BOOLEAN     NOT NULL,
    background_event_count  INT         NOT NULL,
    dropped_frame_count     INT         NOT NULL,
    session_valid           BOOLEAN     NOT NULL,
    timing_deviation_count  INT         NOT NULL,
    validity_issues         TEXT        NOT NULL,
    recorded_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_ca_protocol CHECK (protocol_version = 'ROSVOLD_LONG_V1'),
    CONSTRAINT ck_ca_run_counts CHECK (
        background_event_count >= 0
        AND dropped_frame_count >= 0
        AND timing_deviation_count >= 0)
);

-- 3. Mesures par essai. Les invariants inter-lignes (ordre, séquence, cibles,
-- timeline) sont contrôlés par le domaine pur avant cette écriture.
CREATE TABLE games.continuous_attention_trials (
    session_id                 UUID        NOT NULL
        REFERENCES games.continuous_attention_runs(session_id) ON DELETE CASCADE,
    phase                      VARCHAR(16) NOT NULL,
    block_index                INT         NOT NULL,
    trial_index                INT         NOT NULL,
    previous_letter            CHAR(1),
    current_letter             CHAR(1)     NOT NULL,
    response_code              INT         NOT NULL,
    correct                    INT         NOT NULL,
    latency_ms                 INT,
    scheduled_onset_ms         BIGINT      NOT NULL,
    actual_onset_ms            BIGINT      NOT NULL,
    response_timestamp_ms      BIGINT,
    actual_display_duration_ms INT         NOT NULL,
    actual_isi_duration_ms     INT         NOT NULL,
    input_source               VARCHAR(16),
    extra_response_count       INT         NOT NULL,
    interrupted                BOOLEAN     NOT NULL,
    PRIMARY KEY (session_id, phase, block_index, trial_index),
    CONSTRAINT ck_ca_trial_phase CHECK (
        phase IN ('X_PRACTICE', 'X_TEST', 'AX_PRACTICE', 'AX_TEST')),
    CONSTRAINT ck_ca_trial_block CHECK (
        (phase IN ('X_PRACTICE', 'AX_PRACTICE') AND block_index BETWEEN 1 AND 2)
        OR (phase IN ('X_TEST', 'AX_TEST') AND block_index BETWEEN 1 AND 20)),
    CONSTRAINT ck_ca_trial_index CHECK (trial_index BETWEEN 1 AND 31),
    CONSTRAINT ck_ca_trial_letters CHECK (
        (previous_letter IS NULL OR previous_letter ~ '^[A-Z]$')
        AND current_letter ~ '^[A-Z]$'),
    CONSTRAINT ck_ca_trial_response CHECK (
        (response_code = 0
            AND latency_ms IS NULL
            AND response_timestamp_ms IS NULL
            AND input_source IS NULL)
        OR
        (response_code = 57
            AND latency_ms >= 0 AND latency_ms < 690
            AND response_timestamp_ms IS NOT NULL
            AND input_source IN ('TOUCH', 'KEYBOARD'))),
    CONSTRAINT ck_ca_trial_correct CHECK (correct IN (0, 1)),
    CONSTRAINT ck_ca_trial_nonnegative CHECK (
        scheduled_onset_ms >= 0
        AND actual_onset_ms >= 0
        AND actual_display_duration_ms >= 0
        AND actual_isi_duration_ms >= 0
        AND extra_response_count >= 0),
    CONSTRAINT ck_ca_trial_latency_timestamp CHECK (
        response_timestamp_ms IS NULL
        OR response_timestamp_ms - actual_onset_ms = latency_ms)
);

-- Défense DB contre deux soumissions valides concurrentes, sans modifier les
-- contraintes des mini-jeux historiques.
CREATE UNIQUE INDEX ux_ca_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'CONTINUOUS_ATTENTION_CORE';
