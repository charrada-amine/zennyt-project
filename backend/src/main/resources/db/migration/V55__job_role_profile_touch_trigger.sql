-- Track A, tâche F12 (FITSCORE_REMEDIATION.md §5 A3) — horodatage automatique du
-- référentiel de pondération.
--
-- Le balayage de péremption compare désormais fit_scores.computed_at à
-- job_role_profiles.updated_at : un changement de pondération rend périmés tous les
-- scores calculés avant lui, et le balayage borné existant les reprend.
--
-- Encore faut-il que updated_at bouge. S'en remettre à « celui qui écrit la migration
-- pensera à faire SET updated_at = now() » est précisément le mode de défaillance que
-- F12 doit supprimer : c'est silencieux, et on ne s'en aperçoit qu'en constatant que
-- les scores n'ont jamais été recalculés. Le trigger le garantit, quelle que soit la
-- façon dont la ligne est modifiée — migration, script d'admin, ou future interface.
--
-- Le WHEN évite de réécrire updated_at quand un UPDATE ne change rien, ce qui
-- déclencherait un recalcul complet pour rien.

CREATE OR REPLACE FUNCTION recruitment.touch_job_role_profile()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_job_role_profiles_touch
    BEFORE UPDATE ON recruitment.job_role_profiles
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION recruitment.touch_job_role_profile();
