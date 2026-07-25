-- Renommage des 4 bandes ExperienceLevel (contrat squad web, §3) : la matrice
-- de pondération et les libellés par métier restent les mêmes 4 bandes dans le
-- même ordre — seul le nom de chaque bande change.
-- JUNIOR inchangé ; ex-SENIOR -> MID ; ex-LEAD -> SENIOR ; ex-MANAGER -> EXECUTIVE.

ALTER TABLE recruitment.job_positions RENAME COLUMN senior_label TO mid_label;
ALTER TABLE recruitment.job_positions RENAME COLUMN lead_label TO senior_label;
ALTER TABLE recruitment.job_positions RENAME COLUMN manager_label TO executive_label;

-- Ordre important : SENIOR doit être réécrit en MID avant que LEAD ne devienne SENIOR.
UPDATE recruitment.job_offers SET experience_level = 'MID' WHERE experience_level = 'SENIOR';
UPDATE recruitment.job_offers SET experience_level = 'SENIOR' WHERE experience_level = 'LEAD';
UPDATE recruitment.job_offers SET experience_level = 'EXECUTIVE' WHERE experience_level = 'MANAGER';
