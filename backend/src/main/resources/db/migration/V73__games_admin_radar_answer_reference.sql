-- Emotional Radar answers may now reference either an authoritative scene or a
-- published/archived admin-managed scene. A constraint trigger preserves the
-- original referential guarantee across both games-owned content tables.

ALTER TABLE games.emotional_radar_answers
    DROP CONSTRAINT emotional_radar_answers_scene_id_fkey;

CREATE OR REPLACE FUNCTION games.validate_emotional_radar_answer_scene()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM games.emotional_radar_scenes scene WHERE scene.id = NEW.scene_id
    ) AND NOT EXISTS (
        SELECT 1 FROM games.admin_questions question
         WHERE question.id = NEW.scene_id
           AND question.content_type = 'EMOTIONAL_RADAR_SCENE'
           AND question.status IN ('PUBLISHED', 'ARCHIVED')
    ) THEN
        RAISE EXCEPTION 'Emotional Radar scene % does not exist', NEW.scene_id
            USING ERRCODE = 'foreign_key_violation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE CONSTRAINT TRIGGER ck_emotional_radar_answer_scene_reference
AFTER INSERT OR UPDATE OF scene_id ON games.emotional_radar_answers
DEFERRABLE INITIALLY IMMEDIATE
FOR EACH ROW EXECUTE FUNCTION games.validate_emotional_radar_answer_scene();
