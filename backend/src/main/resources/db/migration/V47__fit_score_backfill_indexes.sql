-- Index de support du balayage de rattrapage des Fit Score
-- (FitScoreBackfillWorker / JpaFitScoreRepository.findPairsNeedingScore).
--
-- La requête sélectionne les paires (candidat actif, offre ACTIVE) sans score,
-- triées par offre la plus anciennement en attente, avec un LIMIT.
-- Sans l'index composite, Postgres peut filtrer sur status via idx_job_offers_status
-- mais doit ensuite trier tous les résultats par posted_at ; avec lui, il parcourt
-- directement dans l'ordre voulu et s'arrête dès qu'il a assez de lignes.
--
-- Les deux autres colonnes de l'anti-jointure sont déjà couvertes :
--   recruitment.actors (active, role)            -> idx_recruitment_actors_active_role (V14)
--   recruitment.fit_scores (candidate_id, job_offer_id) -> uq_fit_scores_candidate_job (V17)

CREATE INDEX idx_job_offers_status_posted_at
    ON recruitment.job_offers (status, posted_at);

-- Détection des scores périmés (JpaFitScoreRepository.findStalePairs) : la requête
-- parcourt les scores existants du plus anciennement calculé au plus récent, avec un
-- LIMIT. Cet index permet de s'arrêter tôt au lieu de trier toute la table.
-- Les deux sous-requêtes corrélées de cette requête sont déjà couvertes par des index
-- uniques existants : soft_skills_projection (candidate_id, module) en V22 et
-- test_results (candidate_id, job_offer_id) en V37.
CREATE INDEX idx_fit_scores_computed_at
    ON recruitment.fit_scores (computed_at);
