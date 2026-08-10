-- F25 (FITSCORE_REMEDIATION.md §3 index F25) — uq_job_positions_name_sector
-- UNIQUE (name, sector) ne protège pas les 9 métiers transverses (sector NULL)
-- des doublons : Postgres traite les NULL comme distincts dans une contrainte
-- d'unicité composite, donc ProposeJobPositionUseCase peut créer autant de
-- métiers transverses de même nom qu'on veut. Un index unique partiel referme
-- ce trou sans toucher à la contrainte existante (qui reste correcte pour les
-- métiers sectoriels).
CREATE UNIQUE INDEX uq_job_positions_name_no_sector
    ON recruitment.job_positions (name)
    WHERE sector IS NULL;
