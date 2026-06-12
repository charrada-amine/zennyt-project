CREATE SCHEMA IF NOT EXISTS recruitment;

CREATE TABLE recruitment.applications (
    id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL,
    job_id UUID NOT NULL,
    cover_letter VARCHAR(4000),
    status VARCHAR(30) NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_applications_candidate_job UNIQUE (candidate_id, job_id),
    CONSTRAINT ck_applications_status CHECK (
        status IN ('SUBMITTED', 'VIEWED', 'SHORTLISTED', 'INTERVIEW', 'OFFER', 'REJECTED', 'WITHDRAWN')
    )
);

CREATE INDEX idx_applications_candidate ON recruitment.applications (candidate_id);
CREATE INDEX idx_applications_job ON recruitment.applications (job_id);
