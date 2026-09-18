-- V84 — Décision comportementale : BART (risque révélé) + IST (recueil d'information).
--
-- Nouveau GameType DECISION_BEHAVIORAL, distinct de DECISION : y ajouter des
-- mini-jeux jouables empêcherait une session « Je Décide » d'atteindre COMPLETED.
--
-- Le client ne persiste que des traces brutes (pompes, ouvertures, horodatages).
-- Points d'éclatement, couleurs révélées, P(correct) et scores sont reconstruits
-- serveur depuis l'UUID de session. Un run techniquement invalide reste audit-only
-- (aucun Attempt) et peut être remplacé, comme pour « Je place » (V63).
--
-- Design : docs/superpowers/specs/2026-09-17-decision-behavioral-games-design.md
-- Preuves : docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md

-- 1. Type de session (dernière définition : V63).
ALTER TABLE games.game_sessions DROP CONSTRAINT IF EXISTS ck_game_sessions_type;
ALTER TABLE games.game_sessions ADD CONSTRAINT ck_game_sessions_type
    CHECK (game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',
                         'EMOTIONAL_REGULATION', 'CONTINUOUS_ATTENTION',
                         'VISUOMOTOR_COORDINATION', 'VISUOSPATIAL_MEMORY',
                         'DECISION_BEHAVIORAL'));

-- 2. Mini-jeux enregistrables (dernière définition : V77). Sans cet élargissement,
--    la première tentative valide échoue en HTTP 500 à l'insertion (cf. V77).
ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE',
                         'CONTINUOUS_ATTENTION_CORE',
                         'COORDINATION_TRACKING_CORE',
                         'OBJECT_LOCATION_BINDING_CORE',
                         'STRATEGIC_CHOICES_CORE',
                         'BART_CORE', 'INFORMATION_SAMPLING_CORE'));

-- 3. Couverture du hub (dernière définition : V78) — liste recopiée à l'identique,
--    plus les deux nouveaux jeux du catalogue.
ALTER TABLE games.player_game_completions
    DROP CONSTRAINT IF EXISTS ck_player_game_completions_key;
ALTER TABLE games.player_game_completions ADD CONSTRAINT ck_player_game_completions_key
    CHECK (game_key IN (
        'MOVE_FAST', 'CONTINUOUS_ATTENTION', 'COORDINATION_TRACKING',
        'MEMORY_QUEST_DIGITS', 'MEMORY_QUEST_IMAGES', 'OBJECT_LOCATION',
        'DECISION', 'OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREDICTIVE_PUZZLE',
        'EMOTIONAL_RADAR', 'REFLECTIVE_PAUSE', 'STRATEGIC_CHOICES',
        'BART', 'INFORMATION_SAMPLING'));

-- 4. Réglages publiés : sessionEnabled conditionne le démarrage de toute session,
--    et V74 exige un SETTINGS et un MODIFIERS publiés par GameType.
INSERT INTO games.admin_configurations
    (id, game_type, configuration_kind, version, values_json, status,
     published_at, created_by, created_at, updated_at)
SELECT d.id, 'DECISION_BEHAVIORAL', d.configuration_kind, 1, d.values_json,
       'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000'::uuid, now(), now()
  FROM (VALUES
        ('82000000-0000-0000-0000-000000000009'::uuid, 'SETTINGS',
         '{"sessionEnabled":true}'::jsonb),
        ('83000000-0000-0000-0000-000000000009'::uuid, 'MODIFIERS',
         '{"reducedMotionDefault":false}'::jsonb)
       ) AS d(id, configuration_kind, values_json)
 WHERE NOT EXISTS (
       SELECT 1 FROM games.admin_configurations existing
        WHERE existing.game_type = 'DECISION_BEHAVIORAL'
          AND existing.configuration_kind = d.configuration_kind);

-- 5. BART ─────────────────────────────────────────────────────────────────────
CREATE TABLE games.bart_runs (
    session_id                    UUID             PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    protocol_version              VARCHAR(40)      NOT NULL,
    session_completed             BOOLEAN          NOT NULL,
    interrupted                   BOOLEAN          NOT NULL,
    background_event_count        INT              NOT NULL,
    focus_loss_count              INT              NOT NULL,
    session_valid                 BOOLEAN          NOT NULL,
    validity_issues               TEXT             NOT NULL,
    test_balloon_count            INT              NOT NULL,
    collected_count               INT              NOT NULL,
    explosion_count               INT              NOT NULL,
    adjusted_average_pumps        DOUBLE PRECISION,
    total_earnings                INT              NOT NULL,
    ev_optimal_earnings           INT              NOT NULL,
    optimal_fixed_pumps           INT              NOT NULL,
    efficiency_percent            INT              NOT NULL,
    mean_pumps_after_explosion    DOUBLE PRECISION,
    mean_pumps_after_collect      DOUBLE PRECISION,
    median_inter_pump_interval_ms DOUBLE PRECISION,
    recorded_at                   TIMESTAMPTZ      NOT NULL DEFAULT now(),
    CONSTRAINT ck_bart_protocol CHECK (protocol_version = 'BART_LEJUEZ_V1'),
    CONSTRAINT ck_bart_counts CHECK (
        background_event_count >= 0 AND focus_loss_count >= 0
        AND test_balloon_count BETWEEN 0 AND 30
        AND collected_count >= 0 AND explosion_count >= 0
        AND collected_count + explosion_count = test_balloon_count),
    CONSTRAINT ck_bart_ranges CHECK (
        total_earnings >= 0 AND ev_optimal_earnings >= 0
        AND optimal_fixed_pumps BETWEEN 0 AND 127
        AND efficiency_percent BETWEEN 0 AND 100
        AND (adjusted_average_pumps IS NULL
             OR adjusted_average_pumps BETWEEN 0 AND 127)),
    CONSTRAINT ck_bart_valid CHECK (session_valid = (validity_issues = ''))
);

CREATE TABLE games.bart_balloons (
    session_id           UUID        NOT NULL
        REFERENCES games.bart_runs(session_id) ON DELETE CASCADE,
    balloon_index        INT         NOT NULL,
    phase                VARCHAR(16) NOT NULL,
    explosion_point      INT         NOT NULL,
    pump_count           INT         NOT NULL,
    outcome              VARCHAR(16) NOT NULL,
    earned_points        INT         NOT NULL,
    collect_timestamp_ms BIGINT,
    PRIMARY KEY (session_id, balloon_index),
    CONSTRAINT ck_bart_balloon_identity CHECK (
        (phase = 'PRACTICE' AND balloon_index BETWEEN 0 AND 1)
        OR (phase = 'TEST' AND balloon_index BETWEEN 2 AND 31)),
    CONSTRAINT ck_bart_balloon_outcome CHECK (
        explosion_point BETWEEN 1 AND 128
        AND ((outcome = 'EXPLODED' AND pump_count = explosion_point
              AND earned_points = 0 AND collect_timestamp_ms IS NULL)
          OR (outcome = 'COLLECTED' AND pump_count BETWEEN 0 AND explosion_point - 1
              AND earned_points >= 0 AND collect_timestamp_ms >= 0)))
);

CREATE TABLE games.bart_pumps (
    session_id    UUID   NOT NULL,
    balloon_index INT    NOT NULL,
    pump_index    INT    NOT NULL,
    timestamp_ms  BIGINT NOT NULL,
    PRIMARY KEY (session_id, balloon_index, pump_index),
    FOREIGN KEY (session_id, balloon_index)
        REFERENCES games.bart_balloons(session_id, balloon_index) ON DELETE CASCADE,
    CONSTRAINT ck_bart_pump CHECK (pump_index BETWEEN 1 AND 128 AND timestamp_ms >= 0)
);

-- 6. IST ──────────────────────────────────────────────────────────────────────
CREATE TABLE games.ist_runs (
    session_id                      UUID             PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    protocol_version                VARCHAR(40)      NOT NULL,
    session_completed               BOOLEAN          NOT NULL,
    interrupted                     BOOLEAN          NOT NULL,
    background_event_count          INT              NOT NULL,
    focus_loss_count                INT              NOT NULL,
    session_valid                   BOOLEAN          NOT NULL,
    validity_issues                 TEXT             NOT NULL,
    test_trial_count                INT              NOT NULL,
    correct_count                   INT              NOT NULL,
    accuracy_percent                DOUBLE PRECISION NOT NULL,
    mean_boxes_fixed_win            DOUBLE PRECISION NOT NULL,
    mean_boxes_decreasing_win       DOUBLE PRECISION NOT NULL,
    condition_discrimination        DOUBLE PRECISION NOT NULL,
    mean_p_correct_at_decision      DOUBLE PRECISION NOT NULL,
    mean_p_correct_fixed_win        DOUBLE PRECISION NOT NULL,
    mean_p_correct_decreasing_win   DOUBLE PRECISION NOT NULL,
    total_earnings                  INT              NOT NULL,
    random_response_count           INT              NOT NULL,
    median_inter_action_interval_ms DOUBLE PRECISION,
    confidence_response_count       INT              NOT NULL,
    -- Biais de calibration SEUL : aucune sensibilité métacognitive (AUROC2,
    -- meta-d') n'est stockée, 20 essais n'y suffisent pas (preuves §4.2).
    calibration_bias                DOUBLE PRECISION,
    provisional_score               INT              NOT NULL,
    recorded_at                     TIMESTAMPTZ      NOT NULL DEFAULT now(),
    CONSTRAINT ck_ist_protocol CHECK (protocol_version = 'IST_CLARK_V1'),
    CONSTRAINT ck_ist_counts CHECK (
        background_event_count >= 0 AND focus_loss_count >= 0
        AND test_trial_count BETWEEN 0 AND 20
        AND correct_count BETWEEN 0 AND test_trial_count
        AND random_response_count BETWEEN 0 AND test_trial_count
        AND confidence_response_count BETWEEN 0 AND test_trial_count),
    CONSTRAINT ck_ist_ranges CHECK (
        accuracy_percent BETWEEN 0 AND 100
        AND mean_boxes_fixed_win BETWEEN 0 AND 25
        AND mean_boxes_decreasing_win BETWEEN 0 AND 25
        AND mean_p_correct_at_decision BETWEEN 0 AND 1
        AND provisional_score BETWEEN 0 AND 100
        AND (calibration_bias IS NULL OR calibration_bias BETWEEN -1 AND 1)),
    CONSTRAINT ck_ist_valid CHECK (session_valid = (validity_issues = ''))
);

CREATE TABLE games.ist_trials (
    session_id            UUID             NOT NULL
        REFERENCES games.ist_runs(session_id) ON DELETE CASCADE,
    trial_index           INT              NOT NULL,
    phase                 VARCHAR(16)      NOT NULL,
    condition             VARCHAR(16)      NOT NULL,
    majority_color        VARCHAR(8)       NOT NULL,
    chosen_color          VARCHAR(8)       NOT NULL,
    correct               BOOLEAN          NOT NULL,
    boxes_opened          INT              NOT NULL,
    blue_seen             INT              NOT NULL,
    orange_seen           INT              NOT NULL,
    p_correct_at_decision DOUBLE PRECISION NOT NULL,
    trial_points          INT              NOT NULL,
    decision_timestamp_ms BIGINT           NOT NULL,
    confidence            INT,
    PRIMARY KEY (session_id, trial_index),
    CONSTRAINT ck_ist_trial_identity CHECK (
        (phase = 'PRACTICE' AND trial_index BETWEEN 0 AND 1)
        OR (phase = 'TEST' AND trial_index BETWEEN 2 AND 21)),
    CONSTRAINT ck_ist_trial_values CHECK (
        condition IN ('FIXED_WIN', 'DECREASING_WIN')
        AND majority_color IN ('BLUE', 'ORANGE')
        AND chosen_color IN ('BLUE', 'ORANGE')
        AND correct = (majority_color = chosen_color)
        AND boxes_opened BETWEEN 0 AND 25
        AND blue_seen >= 0 AND orange_seen >= 0
        AND blue_seen + orange_seen = boxes_opened
        AND p_correct_at_decision BETWEEN 0 AND 1
        AND decision_timestamp_ms >= 0
        AND (confidence IS NULL OR confidence BETWEEN 1 AND 4))
);

CREATE TABLE games.ist_box_openings (
    session_id    UUID   NOT NULL,
    trial_index   INT    NOT NULL,
    opening_index INT    NOT NULL,
    box_index     INT    NOT NULL,
    timestamp_ms  BIGINT NOT NULL,
    PRIMARY KEY (session_id, trial_index, opening_index),
    UNIQUE (session_id, trial_index, box_index),
    FOREIGN KEY (session_id, trial_index)
        REFERENCES games.ist_trials(session_id, trial_index) ON DELETE CASCADE,
    CONSTRAINT ck_ist_opening CHECK (
        opening_index BETWEEN 1 AND 25 AND box_index BETWEEN 0 AND 24
        AND timestamp_ms >= 0)
);

-- 7. Défense DB contre deux résultats valides concurrents pour un même mini-jeu.
CREATE UNIQUE INDEX ux_bart_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'BART_CORE';
CREATE UNIQUE INDEX ux_ist_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'INFORMATION_SAMPLING_CORE';
