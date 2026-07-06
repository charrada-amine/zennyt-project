-- Socle de calibrage APPAREIL (Tâche 4) — méthode « technique » pure.
-- Un calibrage au plus par session (session_id = clé primaire + FK).
-- Les temps BRUTS restent stockés côté métriques ; on conserve ici le profil
-- de calibrage et l'offset calculé pour audit/reproductibilité.
CREATE TABLE IF NOT EXISTS games.device_calibrations (
    session_id UUID PRIMARY KEY
        REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    calibration_method VARCHAR(40) NOT NULL,
    input_mode VARCHAR(20) NOT NULL,
    device_category VARCHAR(20) NOT NULL,
    refresh_rate_hz DOUBLE PRECISION NOT NULL,
    hardware_concurrency INTEGER,
    device_memory_gb DOUBLE PRECISION,
    input_processing_latency_ms DOUBLE PRECISION,
    display_latency_ms DOUBLE PRECISION NOT NULL,
    calibration_offset_ms DOUBLE PRECISION NOT NULL,
    reduced_reliability BOOLEAN NOT NULL,
    CONSTRAINT ck_device_calibrations_method CHECK (
        calibration_method IN ('technique', 'hardware_profile_fallback')
    ),
    CONSTRAINT ck_device_calibrations_input_mode CHECK (
        input_mode IN ('KEYBOARD', 'TOUCH', 'MOUSE', 'SWIPE')
    ),
    CONSTRAINT ck_device_calibrations_category CHECK (
        device_category IN ('MOBILE', 'TABLET', 'DESKTOP')
    ),
    CONSTRAINT ck_device_calibrations_refresh CHECK (refresh_rate_hz > 0)
);
