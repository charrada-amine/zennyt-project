-- File locale durable pour les événements Recruitment dont la projection Engagement a échoué.
CREATE TABLE engagement.pending_application_events (
    event_id        UUID PRIMARY KEY,
    event_type      VARCHAR(100) NOT NULL,
    payload         TEXT NOT NULL,
    attempts        INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    next_attempt_at TIMESTAMPTZ NOT NULL,
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_engagement_pending_events_due
    ON engagement.pending_application_events (next_attempt_at, event_id);
