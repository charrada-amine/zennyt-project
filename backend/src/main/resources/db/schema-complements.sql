-- Compléments au schéma généré par Hibernate.
--
-- Tables, colonnes, clés primaires et étrangères, contraintes CHECK et UNIQUE, index
-- ordinaires et commentaires sont déclarés sur les entités JPA et créés par Hibernate
-- (ddl-auto: update). Ce script ne porte que ce que JPA ne sait pas exprimer :
-- l'extension, les fonctions PL/pgSQL, les triggers, les index partiels ou sur
-- expression, et les index uniques qui ne sont pas des contraintes.
--
-- Exécuté à chaque démarrage, juste après Hibernate (SchemaComplementsInitializer),
-- en une seule transaction. Chaque instruction est idempotente : sur une base à jour,
-- le script ne change rien. Les fonctions sont remplacées à chaque démarrage ; les
-- triggers et index, eux, ne sont créés que s'ils manquent — pour en modifier un, le
-- supprimer explicitement ici avant de le recréer.

-- ── Extension ────────────────────────────────────────────────────────────────

-- Présente depuis V25. gen_random_uuid() est natif depuis PostgreSQL 13, mais
-- l'extension fait partie du schéma historique : une base neuve doit être identique.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- ── Fonctions ────────────────────────────────────────────────────────────────

-- Horodatage automatique du référentiel de pondération (V55, FITSCORE_REMEDIATION.md
-- §5 A3). Le balayage de péremption compare fit_scores.computed_at à
-- job_role_profiles.updated_at : un changement de pondération doit rendre périmés tous
-- les scores calculés avant lui, quelle que soit la façon dont la ligne est modifiée.
CREATE OR REPLACE FUNCTION recruitment.touch_job_role_profile()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Une réponse Emotional Radar V2 est définitive, et l'affectation de la scène ne
-- change jamais après avoir été servie (V68).
CREATE OR REPLACE FUNCTION games.prevent_er_v2_answer_rewrite()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.answered_at IS NOT NULL THEN
        RAISE EXCEPTION 'Emotional Radar V2 answer is immutable for session %, scene %',
            OLD.session_id, OLD.scene_order;
    END IF;
    IF NEW.session_id IS DISTINCT FROM OLD.session_id
        OR NEW.scene_order IS DISTINCT FROM OLD.scene_order
        OR NEW.level IS DISTINCT FROM OLD.level
        OR NEW.target_distance_band IS DISTINCT FROM OLD.target_distance_band
        OR NEW.choice_keys IS DISTINCT FROM OLD.choice_keys
        OR NEW.scene_difficulty IS DISTINCT FROM OLD.scene_difficulty
        OR NEW.correct_emotion_key IS DISTINCT FROM OLD.correct_emotion_key
        OR NEW.stimulus_type IS DISTINCT FROM OLD.stimulus_type
        OR NEW.stimulus_intensity IS DISTINCT FROM OLD.stimulus_intensity
        OR NEW.media_status IS DISTINCT FROM OLD.media_status
        OR NEW.media_url IS DISTINCT FROM OLD.media_url
        OR NEW.contextual_caption IS DISTINCT FROM OLD.contextual_caption
        OR NEW.sensitive_content_flag IS DISTINCT FROM OLD.sensitive_content_flag
        OR NEW.served_at IS DISTINCT FROM OLD.served_at THEN
        RAISE EXCEPTION 'Emotional Radar V2 assignment fields are immutable';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Une réponse Emotional Radar référence soit une scène historique, soit une scène
-- gérée par la console d'administration, publiée ou archivée (V73). Une clé
-- étrangère ne peut viser qu'une table : ce contrôle la remplace sur les deux.
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

-- ── Triggers ─────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger
                    WHERE tgname = 'trg_job_role_profiles_touch'
                      AND tgrelid = 'recruitment.job_role_profiles'::regclass) THEN
        -- Le WHEN évite de réécrire updated_at quand un UPDATE ne change rien, ce qui
        -- déclencherait un recalcul complet des Fit Scores pour rien.
        CREATE TRIGGER trg_job_role_profiles_touch
            BEFORE UPDATE ON recruitment.job_role_profiles
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION recruitment.touch_job_role_profile();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger
                    WHERE tgname = 'trg_er_v2_answer_immutable'
                      AND tgrelid = 'games.emotional_radar_v2_scenes'::regclass) THEN
        CREATE TRIGGER trg_er_v2_answer_immutable
        BEFORE UPDATE ON games.emotional_radar_v2_scenes
        FOR EACH ROW EXECUTE FUNCTION games.prevent_er_v2_answer_rewrite();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger
                    WHERE tgname = 'ck_emotional_radar_answer_scene_reference'
                      AND tgrelid = 'games.emotional_radar_answers'::regclass) THEN
        CREATE CONSTRAINT TRIGGER ck_emotional_radar_answer_scene_reference
        AFTER INSERT OR UPDATE OF scene_id ON games.emotional_radar_answers
        DEFERRABLE INITIALLY IMMEDIATE
        FOR EACH ROW EXECUTE FUNCTION games.validate_emotional_radar_answer_scene();
    END IF;
END
$$;

-- ── Index partiels et sur expression ─────────────────────────────────────────

-- Recherche de compétences insensible à la casse (V1).
CREATE INDEX IF NOT EXISTS idx_skills_name ON public.skills (LOWER(name));

-- Offres rattachées à un métier : l'historique hard skills du candidat se lit par
-- (candidate_id, job_position_id) avec une jointure sur job_offers (V57).
CREATE INDEX IF NOT EXISTS idx_job_offers_position
    ON recruitment.job_offers (job_position_id)
    WHERE job_position_id IS NOT NULL;

-- UNIQUE (name, sector) laisse passer les doublons de métiers transverses (sector
-- NULL) : Postgres traite les NULL comme distincts. Cet index referme le trou (V59).
CREATE UNIQUE INDEX IF NOT EXISTS uq_job_positions_name_no_sector
    ON recruitment.job_positions (name)
    WHERE sector IS NULL;

-- File de travail Fit Score (V56). Déduplication : une seule ligne EN ATTENTE par
-- paire, l'insertion se faisant en ON CONFLICT DO NOTHING ; une paire déjà traitée
-- (DONE) peut être réenfilée plus tard sans conflit.
CREATE UNIQUE INDEX IF NOT EXISTS uq_fitscore_queue_pending
    ON recruitment.fitscore_work_queue (candidate_id, job_offer_id)
    WHERE status = 'PENDING';

-- Consommation : priorité d'abord, puis ancienneté, sur ce que le worker lit
-- réellement — l'index ne grossit pas avec l'historique.
CREATE INDEX IF NOT EXISTS idx_fitscore_queue_claim
    ON recruitment.fitscore_work_queue (priority, created_at)
    WHERE status = 'PENDING';

-- Fragments d'aide dont l'empreinte manque encore, rattrapés en tâche de fond sans
-- balayer toute la table (V66).
CREATE INDEX IF NOT EXISTS idx_engagement_help_chunks_sans_empreinte
    ON engagement.help_article_chunks (id) WHERE embedding IS NULL;

-- Console d'administration des jeux : une seule version publiée à la fois (V69, V70).
CREATE UNIQUE INDEX IF NOT EXISTS ux_admin_bank_one_published_version
    ON games.admin_banks (code) WHERE status = 'PUBLISHED';

CREATE UNIQUE INDEX IF NOT EXISTS ux_admin_config_one_published_version
    ON games.admin_configurations (game_type, configuration_kind)
    WHERE status = 'PUBLISHED';

CREATE UNIQUE INDEX IF NOT EXISTS ux_admin_question_one_published_code
    ON games.admin_questions (content_type, external_code)
    WHERE status = 'PUBLISHED';

-- Défense contre deux résultats valides concurrents pour un même mini-jeu
-- (V61, V62, V63, V86), sans toucher aux contraintes des mini-jeux historiques.
CREATE UNIQUE INDEX IF NOT EXISTS ux_ca_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'CONTINUOUS_ATTENTION_CORE';

CREATE UNIQUE INDEX IF NOT EXISTS ux_coord_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'COORDINATION_TRACKING_CORE';

CREATE UNIQUE INDEX IF NOT EXISTS ux_object_location_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'OBJECT_LOCATION_BINDING_CORE';

CREATE UNIQUE INDEX IF NOT EXISTS ux_bart_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'BART_CORE';

CREATE UNIQUE INDEX IF NOT EXISTS ux_ist_single_valid_attempt
    ON games.game_attempts (session_id, mini_game)
    WHERE mini_game = 'INFORMATION_SAMPLING_CORE';

-- ── Index uniques qui ne sont pas des contraintes ───────────────────────────
-- Hibernate traduit @Index(unique = true) en contrainte UNIQUE ; ces trois-là ont
-- toujours été de simples index uniques.

CREATE UNIQUE INDEX IF NOT EXISTS uq_fit_scores_candidate_job
    ON recruitment.fit_scores (candidate_id, job_offer_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_er_scenes_order
    ON games.emotional_radar_scenes (scene_order);

CREATE UNIQUE INDEX IF NOT EXISTS ux_er_v2_target_per_session
    ON games.emotional_radar_v2_scenes (session_id, correct_emotion_key);
