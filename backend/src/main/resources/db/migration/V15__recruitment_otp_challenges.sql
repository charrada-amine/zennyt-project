CREATE TABLE recruitment.otp_challenges (
    id UUID PRIMARY KEY,
    resource_id UUID NOT NULL,
    recipient_user_id UUID NOT NULL,
    purpose VARCHAR(30) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts_remaining INTEGER NOT NULL CHECK (attempts_remaining >= 0),
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_otp_challenges_resource_purpose_created
    ON recruitment.otp_challenges (resource_id, purpose, created_at DESC);
