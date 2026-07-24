-- Contrat squad web §7 : AssessmentAttempt (+ IntegrityStatus anti-fraude,
-- callback /callbacks/integrity) est remplacé par TestAttempt/TestResult —
-- mélange questions/options par tentative, timeout/abandon explicites, une
-- seule tentative consommée par (jobOfferId, candidateId) pour toujours,
-- appliqué au niveau base (pas seulement en logique applicative).
DROP TABLE IF EXISTS recruitment.assessment_attempts CASCADE;

CREATE TABLE recruitment.test_attempts (
    id UUID PRIMARY KEY,
    job_offer_id UUID NOT NULL,
    hard_skill_test_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    presented_questions_json TEXT,
    status VARCHAR(20) NOT NULL
);
CREATE INDEX idx_test_attempts_candidate_job ON recruitment.test_attempts (candidate_id, job_offer_id);

CREATE TABLE recruitment.test_results (
    id UUID PRIMARY KEY,
    job_offer_id UUID NOT NULL,
    hard_skill_test_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    score INTEGER NOT NULL,
    percentage INTEGER NOT NULL,
    passed BOOLEAN NOT NULL,
    answers_json TEXT,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT uq_test_results_candidate_job UNIQUE (candidate_id, job_offer_id)
);
CREATE INDEX idx_test_results_job_offer ON recruitment.test_results (job_offer_id);

-- Seuil de réussite fixe global (70%, TestResult.PASS_THRESHOLD) remplace le
-- réglage par offre.
ALTER TABLE recruitment.job_offers DROP COLUMN passing_score;
