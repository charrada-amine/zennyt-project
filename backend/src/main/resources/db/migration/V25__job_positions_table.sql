CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE recruitment.job_positions (
    id UUID PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    sector VARCHAR(100),
    profile_type VARCHAR(20),
    calibrated BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
    proposed_by_recruiter_id UUID,
    junior_label VARCHAR(100),
    senior_label VARCHAR(100),
    lead_label VARCHAR(100),
    manager_label VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_job_positions_name_sector UNIQUE (name, sector)
);

CREATE INDEX ix_job_positions_status ON recruitment.job_positions (status);
