-- D1 — le hard skills passe de « le test de cette offre » à « l'historique du candidat
-- sur ce métier ». Deux conséquences en base : des index pour les nouvelles lectures, et
-- un résumé IA re-clé sur le métier plutôt que sur l'offre.

-- 1. Index des nouvelles lectures.
--    L'historique se lit par (candidate_id, job_position_id) avec une jointure sur
--    job_offers ; la requête de péremption fait la même jointure. L'index unique existant
--    (candidate_id, job_offer_id) ne sert plus ces deux accès.
CREATE INDEX IF NOT EXISTS idx_test_results_candidate
    ON recruitment.test_results (candidate_id, completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_offers_position
    ON recruitment.job_offers (job_position_id)
    WHERE job_position_id IS NOT NULL;

-- 2. Le résumé hard skills devient un résumé par métier.
--    Les lignes existantes sont supprimées plutôt que reprises : ce sont des artefacts
--    dérivés, régénérés par le premier test soumis, et les offres sans job_position_id ne
--    pourraient de toute façon pas être converties. Rien d'irremplaçable n'est perdu — la
--    lecture affiche son repli bilingue en attendant.
DELETE FROM recruitment.hard_skills_summary;

ALTER TABLE recruitment.hard_skills_summary
    DROP CONSTRAINT IF EXISTS uq_hard_skills_summary_candidate_offer;

ALTER TABLE recruitment.hard_skills_summary
    DROP COLUMN job_offer_id;

ALTER TABLE recruitment.hard_skills_summary
    ADD COLUMN job_position_id UUID NOT NULL;

ALTER TABLE recruitment.hard_skills_summary
    ADD CONSTRAINT uq_hard_skills_summary_candidate_position
        UNIQUE (candidate_id, job_position_id);
