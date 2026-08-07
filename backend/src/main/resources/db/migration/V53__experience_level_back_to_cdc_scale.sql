-- Phase 0, tâche F31 (FITSCORE_REMEDIATION.md §2 décision D-A, §4 P0.6) —
-- retour à l'échelle de niveaux du cahier des charges.
--
-- V29 avait renommé positionnellement les 4 bandes (JUNIOR inchangé,
-- SENIOR -> MID, LEAD -> SENIOR, MANAGER -> EXECUTIVE) pour suivre le contrat de
-- la squad web. Conséquence non vue à l'époque : le pic du poids hard skills se
-- retrouvait sur MID, et la bande nommée SENIOR portait la pondération que le
-- CdC destine à un Lead (55 % au lieu de 65 % sur un métier Technique). Le
-- CdC §4.1 dit pourtant « Senior / Expert : hard skills dominant ».
--
-- Cette migration est l'inverse exact de V29.
--
-- ATTENTION, CHANGEMENT CASSANT D'API : la valeur `experienceLevel` change dans
-- toutes les requêtes et réponses. La squad web doit être prévenue et une date de
-- bascule convenue avant toute mise en production.

-- ── 1. Colonnes de libellés de job_positions (inverse de V29) ────────────────
-- Ordre important : manager_label doit libérer son nom avant que executive_label
-- ne le reprenne, etc.
ALTER TABLE recruitment.job_positions RENAME COLUMN executive_label TO manager_label;
ALTER TABLE recruitment.job_positions RENAME COLUMN senior_label TO lead_label;
ALTER TABLE recruitment.job_positions RENAME COLUMN mid_label TO senior_label;

-- ── 2. Valeurs de job_offers.experience_level ────────────────────────────────
-- Ordre important : EXECUTIVE doit devenir MANAGER avant que MANAGER ne soit une
-- valeur cible, et SENIOR doit devenir LEAD avant que MID ne devienne SENIOR.
-- Sans cet ordre, une valeur serait réécrite deux fois.
UPDATE recruitment.job_offers SET experience_level = 'MANAGER' WHERE experience_level = 'EXECUTIVE';
UPDATE recruitment.job_offers SET experience_level = 'LEAD'    WHERE experience_level = 'SENIOR';
UPDATE recruitment.job_offers SET experience_level = 'SENIOR'  WHERE experience_level = 'MID';

-- ── 3. Valeurs de job_role_profiles.level (les 24 lignes du référentiel) ─────
-- Même contrainte d'ordre.
UPDATE recruitment.job_role_profiles SET level = 'MANAGER' WHERE level = 'EXECUTIVE';
UPDATE recruitment.job_role_profiles SET level = 'LEAD'    WHERE level = 'SENIOR';
UPDATE recruitment.job_role_profiles SET level = 'SENIOR'  WHERE level = 'MID';

-- Le référentiel vient d'être modifié : marquer les lignes comme telles pour que
-- le futur balayage de péremption (F12) les repère.
UPDATE recruitment.job_role_profiles SET updated_at = now();
