-- Lot C : commande conversation idempotente + idempotence de consommation d'événements.
-- Aucune FK inter-schéma : le contexte Engagement reste découplé de Recruitment/Identity.

-- Projection locale minimale de candidature, alimentée par ApplicationSubmittedEvent.
-- Fournit à Engagement de quoi (re)créer une conversation sans appeler Recruitment.
CREATE TABLE engagement.application_projections (
    application_id UUID PRIMARY KEY,
    job_offer_id   UUID NOT NULL,
    candidate_id   UUID NOT NULL,
    recruiter_id   UUID NOT NULL,
    job_title      VARCHAR(255),
    last_event_id  UUID NOT NULL,
    last_event_at  TIMESTAMPTZ NOT NULL
);

-- Idempotence : un event_id consommé ne produit qu'un seul effet Engagement.
-- Le claim atomique (INSERT ... ON CONFLICT DO NOTHING) arbitre les rejeux.
CREATE TABLE engagement.processed_events (
    event_id     UUID PRIMARY KEY,
    processed_at TIMESTAMPTZ NOT NULL
);
