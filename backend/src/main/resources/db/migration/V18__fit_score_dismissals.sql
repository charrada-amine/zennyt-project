CREATE TABLE recruitment.fit_score_dismissals (
    recruiter_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    dismissed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (recruiter_id, candidate_id, job_offer_id)
);

CREATE INDEX idx_fit_score_dismissals_offer
    ON recruitment.fit_score_dismissals (job_offer_id);
