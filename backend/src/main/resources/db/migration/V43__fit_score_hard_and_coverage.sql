-- CdC Fit Score v3 §3.3 (mécanisme 1 : score×couverture) et §8.3 (hard skill
-- score intégré). coverage_ratio par défaut 100 — pas de suivi de couverture
-- par module côté Games aujourd'hui (D5, PLAN_FITSCORE_V3.md) ; le champ est
-- câblé dès maintenant pour ne pas nécessiter une nouvelle migration quand
-- Games l'exposera.
ALTER TABLE recruitment.fit_scores
    ADD COLUMN hard_skill_score INT,
    ADD COLUMN coverage_ratio INT NOT NULL DEFAULT 100;
