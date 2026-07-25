ALTER TABLE recruitment.job_offers
    ADD COLUMN job_position_id UUID NULL REFERENCES recruitment.job_positions(id);
