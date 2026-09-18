-- Contexte Analytics : read-model alimenté par les Domain Events des autres
-- contextes (jamais par appel direct à leur modèle interne — voir ArchUnit).
-- Décision produit (à valider) : une « candidature » est un swipe RIGHT du
-- candidat sur une offre (intérêt exprimé) ; les vues de profil/offre ne sont
-- pas encore instrumentées.
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE analytics.job_offer_projection (
    job_offer_id UUID PRIMARY KEY,
    recruiter_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    posted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_analytics_job_offer_recruiter
    ON analytics.job_offer_projection(recruiter_id, status);

CREATE TABLE analytics.candidate_activity (
    id BIGSERIAL PRIMARY KEY,
    candidate_id UUID NOT NULL,
    job_offer_id UUID NOT NULL,
    kind VARCHAR(20) NOT NULL,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_analytics_candidate_activity_kind
        CHECK (kind IN ('INTERESTED', 'MATCHED', 'TEST_COMPLETED'))
);

CREATE INDEX idx_analytics_candidate_activity_candidate
    ON analytics.candidate_activity(candidate_id);

CREATE INDEX idx_analytics_candidate_activity_offer
    ON analytics.candidate_activity(job_offer_id);
