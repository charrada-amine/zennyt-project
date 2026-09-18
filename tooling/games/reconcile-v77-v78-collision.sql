-- One-time local repair for the V77/V78 collision (games vs identity), 2026-09-18.
--
-- The games pair V77__games_strategic_choices_minigame.sql and
-- V78__games_player_game_completions.sql arrived after identity had taken V77/V78.
-- Both pairs cannot coexist: Flyway refuses to start ("Found more than one
-- migration with version 77"). As in 608187e, the late games pair is renumbered
-- V84 / V85; its SQL is unchanged, so the checksums are unchanged.
--
-- Run this ONLY on a database that applied the GAMES pair as 77/78 (typically a
-- games-branch database). A database that applied the IDENTITY pair — such as
-- one migrated from main before the games merge — needs nothing: the renumbered
-- games migrations are simply pending there.
--
-- After this script, start the backend ONCE with
--   SPRING_FLYWAY_OUT_OF_ORDER=true
-- so that identity's V77/V78 are applied out of order below the games rows; then
-- restart normally. Back up first. No schema object or game row is modified here.
BEGIN;
LOCK TABLE public.flyway_schema_history IN EXCLUSIVE MODE;
DO $$
BEGIN
    IF (SELECT count(*) FROM public.flyway_schema_history
        WHERE success AND (
          (version = '77' AND script = 'V77__games_strategic_choices_minigame.sql')
          OR (version = '78' AND script = 'V78__games_player_game_completions.sql')
        )) <> 2 THEN
        RAISE EXCEPTION 'Games V77/V78 not applied here; nothing to reconcile';
    END IF;
    IF EXISTS (SELECT 1 FROM public.flyway_schema_history WHERE version IN ('84', '85')) THEN
        RAISE EXCEPTION 'Versions 84/85 already present; refusing migration-history repair';
    END IF;
END $$;
UPDATE public.flyway_schema_history
SET version = CASE version WHEN '77' THEN '84' WHEN '78' THEN '85' END,
    script = CASE version
      WHEN '77' THEN 'V84__games_strategic_choices_minigame.sql'
      WHEN '78' THEN 'V85__games_player_game_completions.sql' END
WHERE version IN ('77', '78')
  AND script IN ('V77__games_strategic_choices_minigame.sql',
                 'V78__games_player_game_completions.sql');
COMMIT;
