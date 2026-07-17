-- Recruitment bounded context — schéma complet (module intégré depuis recruitment_zennyt).
-- Dérivé des entités JPA (source de vérité pour ddl-auto: validate).
-- La table recruitment.applications existe déjà (V2) : on la réconcilie par ALTER, on ne la recrée pas.

CREATE SCHEMA IF NOT EXISTS recruitment;

-- ─────────────────────────────────────────────────────────────────────────────
-- Réconciliation de recruitment.applications (V2 → entité ApplicationEntity)
--   V2 : job_id + CHECK statuts anciens. Entité : job_offer_id + statuts PENDING/SHORTLISTED/APPROVED/REJECTED.
--   (cover_letter/updated_at NOT NULL de V2 restent : colonnes en trop tolérées par validate.)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE recruitment.applications RENAME COLUMN job_id TO job_offer_id;
ALTER TABLE recruitment.applications DROP CONSTRAINT IF EXISTS ck_applications_status;
ALTER TABLE recruitment.applications
    ADD CONSTRAINT ck_applications_status CHECK (status IN ('PENDING', 'SHORTLISTED', 'APPROVED', 'REJECTED'));

-- ─────────────────────────────────────────────────────────────────────────────
-- job_offers
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.job_offers (
    id UUID PRIMARY KEY,
    recruiter_id UUID NOT NULL,
    hiring_contact_id UUID,
    title VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    location_city VARCHAR(255),
    location_country VARCHAR(255),
    location_remote BOOLEAN NOT NULL DEFAULT FALSE,
    salary_min DOUBLE PRECISION,
    salary_max DOUBLE PRECISION,
    salary_currency VARCHAR(255),
    contract_type VARCHAR(255) NOT NULL,
    workplace_type VARCHAR(255) NOT NULL,
    experience_level VARCHAR(255) NOT NULL,
    field_of_work VARCHAR(255),
    description TEXT,
    responsibilities TEXT,
    minimum_qualifications TEXT,
    preferred_qualifications TEXT,
    what_we_offer TEXT,
    how_to_apply TEXT,
    company_info TEXT,
    assessment_id UUID,
    open_to_international BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(255) NOT NULL,
    posted_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_job_offers_recruiter ON recruitment.job_offers (recruiter_id);
CREATE INDEX idx_job_offers_status ON recruitment.job_offers (status);

-- ─────────────────────────────────────────────────────────────────────────────
-- swipes
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.swipes (
    id UUID PRIMARY KEY,
    actor_id UUID NOT NULL,
    target_id UUID NOT NULL,
    target_type VARCHAR(255) NOT NULL,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    direction VARCHAR(255) NOT NULL,
    swiped_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_swipes_actor ON recruitment.swipes (actor_id);
CREATE INDEX idx_swipes_target ON recruitment.swipes (target_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- matches
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.matches (
    id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    recruiter_id UUID NOT NULL,
    job_offer_title VARCHAR(255),
    status VARCHAR(255) NOT NULL,
    matched_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_matches_candidate ON recruitment.matches (candidate_id);
CREATE INDEX idx_matches_recruiter ON recruitment.matches (recruiter_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- fit_scores
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.fit_scores (
    id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    score INTEGER NOT NULL,
    computed_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_fit_scores_candidate_job ON recruitment.fit_scores (candidate_id, job_offer_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- assessments (questions sérialisées en JSON dans questions_json)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.assessments (
    id UUID PRIMARY KEY,
    created_by_recruiter_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    time_limit_seconds INTEGER NOT NULL,
    max_questions INTEGER NOT NULL,
    generation_source VARCHAR(255),
    shareable_link VARCHAR(255),
    questions_json TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_assessments_recruiter ON recruitment.assessments (created_by_recruiter_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- assessment_attempts
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.assessment_attempts (
    id UUID PRIMARY KEY,
    assessment_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    passed BOOLEAN NOT NULL DEFAULT FALSE,
    integrity_status VARCHAR(255) NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_attempts_assessment ON recruitment.assessment_attempts (assessment_id);
CREATE INDEX idx_attempts_candidate ON recruitment.assessment_attempts (candidate_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- identity_verifications
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.identity_verifications (
    id UUID PRIMARY KEY,
    requested_by_recruiter_id UUID NOT NULL,
    target_candidate_id UUID NOT NULL,
    job_offer_id UUID,
    status VARCHAR(255) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_identity_verif_target ON recruitment.identity_verifications (target_candidate_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- job_opportunity_offers (recruteur → candidat, flux OTP)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.job_opportunity_offers (
    id UUID PRIMARY KEY,
    recruiter_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    title VARCHAR(255),
    salary_min DOUBLE PRECISION,
    salary_max DOUBLE PRECISION,
    salary_currency VARCHAR(255),
    status VARCHAR(255) NOT NULL,
    otp_verified BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL,
    responded_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_opportunity_candidate ON recruitment.job_opportunity_offers (candidate_id);
CREATE INDEX idx_opportunity_recruiter ON recruitment.job_opportunity_offers (recruiter_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- video_conference_payments (9.99 EUR, flux OTP)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE recruitment.video_conference_payments (
    id UUID PRIMARY KEY,
    recruiter_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    match_id UUID NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    tax DOUBLE PRECISION NOT NULL DEFAULT 0,
    total DOUBLE PRECISION NOT NULL DEFAULT 0,
    currency VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    payment_method_last4 VARCHAR(255),
    payment_method_type VARCHAR(255),
    otp_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_payments_recruiter ON recruitment.video_conference_payments (recruiter_id);
CREATE INDEX idx_payments_match ON recruitment.video_conference_payments (match_id);
