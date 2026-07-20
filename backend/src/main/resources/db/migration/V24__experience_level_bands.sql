-- ExperienceLevel remaniée sur les 4 bandes de la matrice Fit Score
-- (Junior/Senior/Lead/Manager) au lieu de (Junior/Mid/Senior/Executive) —
-- voir PLAN_FITSCORE_V3.md décision D8. MID est absorbé par SENIOR (le plus
-- proche des deux), EXECUTIVE devient MANAGER ; LEAD est un niveau neuf, sans
-- équivalent dans l'ancien schéma.
UPDATE recruitment.job_offers SET experience_level = 'SENIOR' WHERE experience_level = 'MID';
UPDATE recruitment.job_offers SET experience_level = 'MANAGER' WHERE experience_level = 'EXECUTIVE';
