-- One-time, explicitly approved local repair, 2026-09-06.
-- Back up first. Compare the existing attention/coordination/object-location
-- schema with a database migrated from this checkout before executing.
-- This does NOT mark the missing Decision migration as applied: Flyway must
-- execute V59 out of order afterwards, then the remaining pending migrations.
-- No game rows, migration files or schema objects are modified here.
BEGIN;
LOCK TABLE public.flyway_schema_history IN EXCLUSIVE MODE;
DO $$
BEGIN
    IF (SELECT count(*) FROM public.flyway_schema_history
        WHERE success AND (
          (version = '59' AND script = 'V59__games_continuous_attention.sql' AND checksum = 1460595362)
          OR (version = '60' AND script = 'V60__games_visuomotor_coordination.sql' AND checksum = -1546060340)
          OR (version = '61' AND script = 'V61__games_object_location_memory.sql' AND checksum = -783636293)
        )) <> 3 OR EXISTS (
          SELECT 1 FROM public.flyway_schema_history WHERE version = '62'
        ) OR to_regclass('games.decision_scenarios') IS NOT NULL THEN
        RAISE EXCEPTION 'Not the audited legacy database; refusing migration-history repair';
    END IF;
    IF to_regclass('games.continuous_attention_runs') IS NULL
       OR to_regclass('games.coordination_tracking_runs') IS NULL
       OR to_regclass('games.object_location_runs') IS NULL THEN
        RAISE EXCEPTION 'Expected legacy game tables are missing';
    END IF;
END $$;
UPDATE public.flyway_schema_history
SET version = (version::int + 1)::text,
    script = CASE version
      WHEN '59' THEN 'V60__games_continuous_attention.sql'
      WHEN '60' THEN 'V61__games_visuomotor_coordination.sql'
      WHEN '61' THEN 'V62__games_object_location_memory.sql' END,
    checksum = CASE version
      WHEN '59' THEN -417744484
      WHEN '60' THEN 1692668671
      WHEN '61' THEN 1538240054 END
WHERE version IN ('59', '60', '61');
COMMIT;
