ALTER TABLE recruitment.assessment_attempts
    ADD COLUMN monitoring_consent BOOLEAN NOT NULL DEFAULT FALSE;
