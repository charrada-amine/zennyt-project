-- Track B, tâche F32 (FITSCORE_REMEDIATION.md §6, décision D-C) — le mode
-- d'évaluation du hard skills appartient au MÉTIER, pas à la famille de métiers.
--
-- Le CdC se contredit lui-même : §8.1 place type_evaluation_hard sur job_role_profile
-- (donc profil × niveau), tandis que §4.3 et §10 assignent les modes PAR MÉTIER —
-- UX/UI Designer et Motion designer en Mixte, Illustrateur / Photographe / Compositeur /
-- Scénariste / Directeur artistique en Portfolio. Or ces métiers sont tous ARTISTIQUE :
-- avec le champ sur job_role_profile, ils partagent forcément le même mode, et l'intention
-- documentée est littéralement inexprimable.
--
-- D-C a tranché pour le métier. C'est aussi le seul choix qui a du sens : deux métiers de
-- la même famille peuvent avoir des preuves de compétence très différentes.

ALTER TABLE recruitment.job_positions
    ADD COLUMN type_evaluation_hard VARCHAR(20) NOT NULL DEFAULT 'QCM',
    ADD CONSTRAINT ck_job_positions_type_evaluation_hard
        CHECK (type_evaluation_hard IN ('QCM', 'PORTFOLIO', 'MIXTE'));

-- Reprise : les métiers créatifs héritent du PORTFOLIO que portait leur profil.
UPDATE recruitment.job_positions
   SET type_evaluation_hard = 'PORTFOLIO'
 WHERE profile_type = 'ARTISTIQUE';

-- Puis les deux métiers hybrides nommément désignés par le CdC §4.3 passent en MIXTE :
-- QCM sur la méthodologie et les outils, Portfolio sur le jugement esthétique.
-- Le calcul du Score_Hard en mode MIXTE n'est pas encore implémenté (ni poids_qcm ni
-- poids_portfolio n'existent) ; ces deux lignes rendent l'intention du CdC EXPRIMABLE,
-- pas encore effective. Voir D-F, qui a reporté la grille portfolio.
UPDATE recruitment.job_positions
   SET type_evaluation_hard = 'MIXTE'
 WHERE profile_type = 'ARTISTIQUE'
   AND name IN ('UX/UI Designer', 'UX/UI e-commerce', 'Motion designer');

-- Le champ quitte job_role_profiles : le garder aux deux endroits laisserait deux
-- sources de vérité qui divergeraient au premier oubli.
ALTER TABLE recruitment.job_role_profiles
    DROP COLUMN type_evaluation_hard;
