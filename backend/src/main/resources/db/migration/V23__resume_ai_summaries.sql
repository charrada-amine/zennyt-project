CREATE TABLE recruitment.soft_skills_summary (
    candidate_id UUID PRIMARY KEY,
    text_fr TEXT NOT NULL,
    text_en TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE recruitment.hard_skills_summary (
    id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    text_fr TEXT NOT NULL,
    text_en TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_hard_skills_summary_candidate_offer UNIQUE (candidate_id, job_offer_id)
);
