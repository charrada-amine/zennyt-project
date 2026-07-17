ALTER TABLE recruitment.fit_scores
    ADD COLUMN soft_skill_score INTEGER;

ALTER TABLE recruitment.fit_scores
    ADD COLUMN cv_match_score INTEGER;

ALTER TABLE recruitment.fit_scores
    ADD CONSTRAINT ck_fit_scores_soft_skill_score
        CHECK (soft_skill_score IS NULL OR soft_skill_score BETWEEN 0 AND 100);

ALTER TABLE recruitment.fit_scores
    ADD CONSTRAINT ck_fit_scores_cv_match_score
        CHECK (cv_match_score IS NULL OR cv_match_score BETWEEN 0 AND 100);

CREATE TABLE recruitment.soft_skills_projection (
    candidate_id UUID PRIMARY KEY,
    score INTEGER NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_soft_skills_projection_score CHECK (score BETWEEN 0 AND 100)
);

-- L'ancien callback pouvait laisser plusieurs lignes pour une paire. Conserver
-- la plus récente avant de verrouiller l'invariant d'upsert.
DELETE FROM recruitment.fit_scores
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY candidate_id, job_offer_id
                   ORDER BY computed_at DESC, id DESC
               ) AS duplicate_rank
        FROM recruitment.fit_scores
    ) ranked
    WHERE duplicate_rank > 1
);

CREATE UNIQUE INDEX uq_fit_scores_candidate_job
    ON recruitment.fit_scores (candidate_id, job_offer_id);
