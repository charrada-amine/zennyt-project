-- Published non-scoring defaults for every live GameType. Existing published
-- choices are preserved; only missing SETTINGS/MODIFIERS streams are seeded.

WITH defaults(game_type, configuration_kind, id, values_json) AS (
    VALUES
        ('PLANIFIK', 'SETTINGS', '82000000-0000-0000-0000-000000000001'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('MOVE_FAST', 'SETTINGS', '82000000-0000-0000-0000-000000000002'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('MEMORY_QUEST', 'SETTINGS', '82000000-0000-0000-0000-000000000003'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('DECISION', 'SETTINGS', '82000000-0000-0000-0000-000000000004'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('EMOTIONAL_REGULATION', 'SETTINGS', '82000000-0000-0000-0000-000000000005'::uuid,
         '{"sessionEnabled":true,"sceneCount":3,"orderMode":"SEQUENTIAL","helpEnabled":true}'::jsonb),
        ('CONTINUOUS_ATTENTION', 'SETTINGS', '82000000-0000-0000-0000-000000000006'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('VISUOMOTOR_COORDINATION', 'SETTINGS', '82000000-0000-0000-0000-000000000007'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('VISUOSPATIAL_MEMORY', 'SETTINGS', '82000000-0000-0000-0000-000000000008'::uuid,
         '{"sessionEnabled":true}'::jsonb),
        ('PLANIFIK', 'MODIFIERS', '83000000-0000-0000-0000-000000000001'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('MOVE_FAST', 'MODIFIERS', '83000000-0000-0000-0000-000000000002'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('MEMORY_QUEST', 'MODIFIERS', '83000000-0000-0000-0000-000000000003'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('DECISION', 'MODIFIERS', '83000000-0000-0000-0000-000000000004'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('EMOTIONAL_REGULATION', 'MODIFIERS', '83000000-0000-0000-0000-000000000005'::uuid,
         '{"reducedMotionDefault":false,"answerFeedback":true,"transitionDurationMs":900}'::jsonb),
        ('CONTINUOUS_ATTENTION', 'MODIFIERS', '83000000-0000-0000-0000-000000000006'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('VISUOMOTOR_COORDINATION', 'MODIFIERS', '83000000-0000-0000-0000-000000000007'::uuid,
         '{"reducedMotionDefault":false}'::jsonb),
        ('VISUOSPATIAL_MEMORY', 'MODIFIERS', '83000000-0000-0000-0000-000000000008'::uuid,
         '{"reducedMotionDefault":false}'::jsonb)
)
INSERT INTO games.admin_configurations
    (id, game_type, configuration_kind, version, values_json, status,
     published_at, created_by, created_at, updated_at)
SELECT d.id, d.game_type, d.configuration_kind,
       COALESCE((SELECT max(existing.version) + 1
                   FROM games.admin_configurations existing
                  WHERE existing.game_type = d.game_type
                    AND existing.configuration_kind = d.configuration_kind), 1),
       d.values_json, 'PUBLISHED', now(),
       '00000000-0000-0000-0000-000000000000'::uuid, now(), now()
  FROM defaults d
 WHERE NOT EXISTS (
       SELECT 1
         FROM games.admin_configurations published
        WHERE published.game_type = d.game_type
          AND published.configuration_kind = d.configuration_kind
          AND published.status = 'PUBLISHED'
 );

DO $$
BEGIN
    IF (SELECT count(DISTINCT game_type)
          FROM games.admin_configurations
         WHERE status = 'PUBLISHED' AND configuration_kind = 'SETTINGS') <> 8 THEN
        RAISE EXCEPTION 'Every GameType must have one published SETTINGS version';
    END IF;
    IF (SELECT count(DISTINCT game_type)
          FROM games.admin_configurations
         WHERE status = 'PUBLISHED' AND configuration_kind = 'MODIFIERS') <> 8 THEN
        RAISE EXCEPTION 'Every GameType must have one published MODIFIERS version';
    END IF;
END $$;
