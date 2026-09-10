-- Emotional Radar V2 Phase A : affectations adaptatives et réponses immuables.
-- Les médias restent explicitement PLACEHOLDER_PENDING jusqu'à livraison/norming.

CREATE TABLE games.emotional_radar_v2_scenes (
    session_id                UUID             NOT NULL
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    scene_order               INT              NOT NULL,
    level                     INT              NOT NULL,
    target_distance_band      VARCHAR(16)      NOT NULL,
    choice_keys               TEXT             NOT NULL,
    scene_difficulty          DOUBLE PRECISION NOT NULL,
    correct_emotion_key       VARCHAR(64)      NOT NULL,
    stimulus_type             VARCHAR(16)      NOT NULL,
    stimulus_intensity        INT              NOT NULL,
    media_status              VARCHAR(32)      NOT NULL,
    media_url                 TEXT,
    contextual_caption        TEXT,
    sensitive_content_flag    BOOLEAN          NOT NULL,
    served_at                 TIMESTAMPTZ      NOT NULL,
    selected_emotion_key      VARCHAR(64),
    selected_intensity        INT,
    explanation               TEXT,
    response_time_ms          INT,
    timed_out                 BOOLEAN,
    impulsive                 BOOLEAN,
    semantic_error_distance   DOUBLE PRECISION,
    answered_at               TIMESTAMPTZ,
    PRIMARY KEY (session_id, scene_order),
    CONSTRAINT ck_er_v2_scene_order CHECK (scene_order BETWEEN 1 AND 15),
    CONSTRAINT ck_er_v2_level CHECK (level BETWEEN 1 AND 4),
    CONSTRAINT ck_er_v2_band CHECK (target_distance_band IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT ck_er_v2_difficulty CHECK (scene_difficulty BETWEEN 0.0 AND 1.0),
    CONSTRAINT ck_er_v2_stimulus_type CHECK (
        stimulus_type IN ('FACIAL', 'BODY', 'SOCIAL', 'CONTEXTUAL')),
    CONSTRAINT ck_er_v2_stimulus_intensity CHECK (stimulus_intensity BETWEEN 0 AND 2),
    CONSTRAINT ck_er_v2_media_status CHECK (
        media_status IN ('PLACEHOLDER_PENDING', 'READY')),
    CONSTRAINT ck_er_v2_placeholder CHECK (
        media_status <> 'PLACEHOLDER_PENDING' OR media_url IS NULL),
    CONSTRAINT ck_er_v2_ready_media CHECK (
        media_status <> 'READY' OR (media_url IS NOT NULL AND media_url <> '')),
    CONSTRAINT ck_er_v2_context_caption CHECK (
        media_status <> 'READY' OR stimulus_type <> 'CONTEXTUAL'
        OR (contextual_caption IS NOT NULL AND contextual_caption <> '')),
    CONSTRAINT ck_er_v2_answer_all_or_none CHECK (
        (answered_at IS NULL
            AND selected_emotion_key IS NULL
            AND selected_intensity IS NULL
            AND explanation IS NULL
            AND response_time_ms IS NULL
            AND timed_out IS NULL
            AND impulsive IS NULL
            AND semantic_error_distance IS NULL)
        OR
        (answered_at IS NOT NULL
            AND selected_emotion_key IS NOT NULL
            AND selected_intensity BETWEEN 0 AND 2
            AND explanation IS NOT NULL AND explanation <> ''
            AND response_time_ms BETWEEN 0 AND 8000
            AND timed_out IS NOT NULL
            AND impulsive IS NOT NULL
            AND semantic_error_distance BETWEEN 0.0 AND 1.0))
);

CREATE INDEX ix_er_v2_scenes_session
    ON games.emotional_radar_v2_scenes (session_id, scene_order);

CREATE UNIQUE INDEX ux_er_v2_target_per_session
    ON games.emotional_radar_v2_scenes (session_id, correct_emotion_key);

CREATE OR REPLACE FUNCTION games.prevent_er_v2_answer_rewrite()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.answered_at IS NOT NULL THEN
        RAISE EXCEPTION 'Emotional Radar V2 answer is immutable for session %, scene %',
            OLD.session_id, OLD.scene_order;
    END IF;
    IF NEW.session_id IS DISTINCT FROM OLD.session_id
        OR NEW.scene_order IS DISTINCT FROM OLD.scene_order
        OR NEW.level IS DISTINCT FROM OLD.level
        OR NEW.target_distance_band IS DISTINCT FROM OLD.target_distance_band
        OR NEW.choice_keys IS DISTINCT FROM OLD.choice_keys
        OR NEW.scene_difficulty IS DISTINCT FROM OLD.scene_difficulty
        OR NEW.correct_emotion_key IS DISTINCT FROM OLD.correct_emotion_key
        OR NEW.stimulus_type IS DISTINCT FROM OLD.stimulus_type
        OR NEW.stimulus_intensity IS DISTINCT FROM OLD.stimulus_intensity
        OR NEW.media_status IS DISTINCT FROM OLD.media_status
        OR NEW.media_url IS DISTINCT FROM OLD.media_url
        OR NEW.contextual_caption IS DISTINCT FROM OLD.contextual_caption
        OR NEW.sensitive_content_flag IS DISTINCT FROM OLD.sensitive_content_flag
        OR NEW.served_at IS DISTINCT FROM OLD.served_at THEN
        RAISE EXCEPTION 'Emotional Radar V2 assignment fields are immutable';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_er_v2_answer_immutable
BEFORE UPDATE ON games.emotional_radar_v2_scenes
FOR EACH ROW EXECUTE FUNCTION games.prevent_er_v2_answer_rewrite();
