-- Refonte du modèle Swipe (contrat squad web §5.1) : état courant par
-- (jobOfferId, candidateId, side) au lieu d'un modèle acteur/cible polymorphe.
-- direction devient RIGHT/LEFT (ex-LIKE/PASS). Table recréée : l'ancienne
-- structure (actor_id/target_id/target_type) n'a pas d'équivalent direct.
DROP TABLE IF EXISTS recruitment.swipes CASCADE;

CREATE TABLE recruitment.swipes (
    id UUID PRIMARY KEY,
    job_offer_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    side VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_swipes_pair_side UNIQUE (job_offer_id, candidate_id, side)
);
CREATE INDEX idx_swipes_job_offer ON recruitment.swipes (job_offer_id);
CREATE INDEX idx_swipes_candidate ON recruitment.swipes (candidate_id);
