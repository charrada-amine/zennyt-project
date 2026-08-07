-- P5 — chaque résumé existe désormais en deux versions : une pour le recruteur
-- (objective et factuelle), une pour le candidat (diplomatique et motivante). Même fond,
-- formulation différente. Le public fait donc partie de la clé, il n'est pas un attribut :
-- les deux versions coexistent pour un même candidat.
--
-- 2 sections (soft, hard) x 2 publics = les 4 résumés d'un candidat sur un métier.

ALTER TABLE recruitment.soft_skills_summary
    ADD COLUMN audience VARCHAR(16) NOT NULL DEFAULT 'RECRUITER';

-- La clé primaire passe de (candidate_id) à (candidate_id, audience). Les lignes déjà
-- présentes ont été rédigées pour le recruteur : la valeur par défaut les qualifie
-- correctement, aucune n'est perdue.
ALTER TABLE recruitment.soft_skills_summary
    DROP CONSTRAINT soft_skills_summary_pkey;

ALTER TABLE recruitment.soft_skills_summary
    ADD CONSTRAINT soft_skills_summary_pkey PRIMARY KEY (candidate_id, audience);

ALTER TABLE recruitment.hard_skills_summary
    ADD COLUMN audience VARCHAR(16) NOT NULL DEFAULT 'RECRUITER';

ALTER TABLE recruitment.hard_skills_summary
    DROP CONSTRAINT uq_hard_skills_summary_candidate_position;

ALTER TABLE recruitment.hard_skills_summary
    ADD CONSTRAINT uq_hard_skills_summary_candidate_position
        UNIQUE (candidate_id, job_position_id, audience);

-- La valeur par défaut a joué son rôle de reprise ; la garder inviterait à insérer sans
-- public explicite, ce que le code ne fait jamais.
ALTER TABLE recruitment.soft_skills_summary ALTER COLUMN audience DROP DEFAULT;
ALTER TABLE recruitment.hard_skills_summary ALTER COLUMN audience DROP DEFAULT;
