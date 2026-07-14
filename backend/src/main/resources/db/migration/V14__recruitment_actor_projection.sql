CREATE TABLE recruitment.actors (
    public_user_id UUID PRIMARY KEY,
    role VARCHAR(30) NOT NULL,
    active BOOLEAN NOT NULL,
    last_event_at TIMESTAMPTZ NOT NULL,
    last_event_id UUID NOT NULL
);

CREATE INDEX idx_recruitment_actors_active_role
    ON recruitment.actors (active, role);
