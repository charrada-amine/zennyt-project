ALTER TABLE recruitment.assessment_attempts
    ADD COLUMN application_id UUID;

ALTER TABLE recruitment.job_offers
    ADD COLUMN passing_score INTEGER NOT NULL DEFAULT 60;

ALTER TABLE recruitment.job_offers
    ADD CONSTRAINT ck_job_offers_passing_score
        CHECK (passing_score BETWEEN 0 AND 100);

CREATE INDEX idx_attempts_application
    ON recruitment.assessment_attempts (application_id);
