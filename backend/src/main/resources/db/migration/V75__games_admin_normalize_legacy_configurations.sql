-- Convert any already-published free-form configuration to the typed V70
-- allowlist. The original version is archived; valid values are preserved in
-- a new published version so audit history remains immutable.

DO $$
DECLARE
    current_configuration RECORD;
    normalized JSONB;
    next_version INT;
    next_id UUID;
BEGIN
    FOR current_configuration IN
        SELECT *
          FROM games.admin_configurations
         WHERE status = 'PUBLISHED'
         ORDER BY game_type, configuration_kind
    LOOP
        IF current_configuration.configuration_kind = 'SETTINGS'
           AND current_configuration.game_type = 'EMOTIONAL_REGULATION' THEN
            normalized := jsonb_build_object(
                'sessionEnabled', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'sessionEnabled') = 'boolean'
                    THEN (current_configuration.values_json ->> 'sessionEnabled')::boolean
                    ELSE true END,
                'sceneCount', CASE
                    WHEN current_configuration.values_json ->> 'sceneCount' ~ '^[0-9]+$'
                    THEN greatest(1, least(15, (current_configuration.values_json ->> 'sceneCount')::int))
                    ELSE 3 END,
                'orderMode', CASE
                    WHEN current_configuration.values_json ->> 'orderMode' IN ('SEQUENTIAL', 'SHUFFLED')
                    THEN current_configuration.values_json ->> 'orderMode'
                    ELSE 'SEQUENTIAL' END,
                'helpEnabled', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'helpEnabled') = 'boolean'
                    THEN (current_configuration.values_json ->> 'helpEnabled')::boolean
                    ELSE true END
            );
        ELSIF current_configuration.configuration_kind = 'SETTINGS' THEN
            normalized := jsonb_build_object(
                'sessionEnabled', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'sessionEnabled') = 'boolean'
                    THEN (current_configuration.values_json ->> 'sessionEnabled')::boolean
                    ELSE true END
            );
        ELSIF current_configuration.game_type = 'EMOTIONAL_REGULATION' THEN
            normalized := jsonb_build_object(
                'reducedMotionDefault', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'reducedMotionDefault') = 'boolean'
                    THEN (current_configuration.values_json ->> 'reducedMotionDefault')::boolean
                    ELSE false END,
                'answerFeedback', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'answerFeedback') = 'boolean'
                    THEN (current_configuration.values_json ->> 'answerFeedback')::boolean
                    ELSE true END,
                'transitionDurationMs', CASE
                    WHEN current_configuration.values_json ->> 'transitionDurationMs' ~ '^[0-9]+$'
                    THEN greatest(0, least(5000,
                        (current_configuration.values_json ->> 'transitionDurationMs')::int))
                    ELSE 900 END
            );
        ELSE
            normalized := jsonb_build_object(
                'reducedMotionDefault', CASE
                    WHEN jsonb_typeof(current_configuration.values_json -> 'reducedMotionDefault') = 'boolean'
                    THEN (current_configuration.values_json ->> 'reducedMotionDefault')::boolean
                    ELSE false END
            );
        END IF;

        IF current_configuration.values_json <> normalized THEN
            UPDATE games.admin_configurations
               SET status = 'ARCHIVED', updated_at = now()
             WHERE id = current_configuration.id;

            SELECT max(version) + 1 INTO next_version
              FROM games.admin_configurations
             WHERE game_type = current_configuration.game_type
               AND configuration_kind = current_configuration.configuration_kind;
            next_id := md5(current_configuration.game_type || ':'
                || current_configuration.configuration_kind || ':'
                || next_version::text || ':V71')::uuid;

            INSERT INTO games.admin_configurations
                (id, game_type, configuration_kind, version, values_json, status,
                 published_at, created_by, created_at, updated_at)
            VALUES
                (next_id, current_configuration.game_type,
                 current_configuration.configuration_kind, next_version, normalized,
                 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000'::uuid,
                 now(), now());
        END IF;
    END LOOP;
END $$;

DO $$
BEGIN
    IF (SELECT count(*) FROM games.admin_configurations
         WHERE status = 'PUBLISHED') <> 16 THEN
        RAISE EXCEPTION 'Typed configuration streams must contain exactly 16 published versions';
    END IF;
END $$;
