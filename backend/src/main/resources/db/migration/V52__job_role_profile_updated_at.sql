-- Phase 0, tâche F11 (FITSCORE_REMEDIATION.md §4 P0.2) — horodatage du
-- référentiel de pondération.
--
-- Le CdC §10 et 16-prochaines-etapes.md demandent tous deux un mécanisme
-- d'audit/versioning sur les profils de pondération. PLAN_FITSCORE_V3.md avait
-- acté la mitigation minimale (« prévoir simplement updated_at + calibrated dès
-- la V20 pour ne pas se fermer la porte ») : seul `calibrated` avait été livré.
--
-- C'est le prérequis de F12 : aujourd'hui aucun recalcul ne se déclenche quand
-- la pondération change, et `findStalePairs` ne compare que des horodatages côté
-- candidat. L'atelier RH — prérequis déclaré de la mise en production — ne
-- produira que des pondérations nouvelles : sans cette colonne, rien ne pourra
-- détecter que tous les fit_scores en cache sont devenus périmés.

ALTER TABLE recruitment.job_role_profiles
    ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now();
