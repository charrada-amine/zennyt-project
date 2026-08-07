-- Track A, tâches F13 + F15 (FITSCORE_REMEDIATION.md §5 A2) — couverture par module.
--
-- Le CdC §3.3 définit la couverture comme une propriété PAR MODULE
-- (`Score_module_i × f(Couverture_i)`), appliquée avant l'agrégation. Jusqu'ici
-- elle n'existait nulle part : `RecomputeFitScoresUseCase` passait un
-- DEFAULT_COVERAGE_RATIO figé à 100, et `fit_scores.coverage_ratio` ne portait
-- qu'une valeur globale, incapable d'exprimer « le candidat a couvert 100 % de
-- Move Fast mais 40 % de Planifik ».
--
-- La colonne se place donc sur la projection par module, seul endroit où une
-- valeur par module a un sens. `fit_scores.coverage_ratio` reste la couverture
-- agrégée, conservée pour l'affichage et pour les seuils du mécanisme 2.
--
-- DEFAULT 100 : les lignes déjà écrites proviennent de sessions Games qui
-- n'émettent qu'à complétion totale (voir F14), leur couverture est donc bien
-- de 100 %. Aucune reprise de données n'est nécessaire.

ALTER TABLE recruitment.soft_skills_projection
    ADD COLUMN coverage_ratio INT NOT NULL DEFAULT 100;

ALTER TABLE recruitment.soft_skills_projection
    ADD CONSTRAINT ck_soft_skills_projection_coverage
        CHECK (coverage_ratio BETWEEN 0 AND 100);
