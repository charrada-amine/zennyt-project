-- Radar émotionnel v2 — la justification écrite devient facultative.
--
-- Deux défauts corrigés d'un coup dans `ck_er_v2_answer_all_or_none`, tous deux
-- invisibles en test et fatals en partie réelle (HTTP 500 à la validation) :
--
-- 1. `explanation <> ''` — la troisième question a été retirée de l'écran à la
--    demande du client. Le client envoie désormais une chaîne vide ; le domaine
--    l'accepte, mais la base la refusait encore. On garde `IS NOT NULL` : le
--    « tout ou rien » continue de distinguer une scène répondue d'une scène
--    intacte, la chaîne vide valant « pas de texte » et non « pas de réponse ».
--
-- 2. `response_time_ms BETWEEN 0 AND 8000` — le budget de réponse est passé de
--    8 s à 30 s, sans que cette borne suive. Toute réponse au-delà de 8 s
--    échouait donc, y compris chaque dépassement de délai, qui enregistre
--    exactement 30 000 ms. On ne remplace PAS 8000 par 30000 : redupliquer une
--    constante applicative dans le schéma est précisément ce qui a cassé ici.
--    Le plafond reste tenu là où il est défini — `EmotionalRadarV2Config`
--    .MAX_RESPONSE_TIME_MS, appliqué par le clamp de `RadarV2SceneAssignment
--    .answer` — et la base ne garde que ce qui ne dépend d'aucun réglage :
--    une durée n'est pas négative.

ALTER TABLE games.emotional_radar_v2_scenes
    DROP CONSTRAINT ck_er_v2_answer_all_or_none;

ALTER TABLE games.emotional_radar_v2_scenes
    ADD CONSTRAINT ck_er_v2_answer_all_or_none CHECK (
        (answered_at IS NULL
            AND selected_emotion_key IS NULL
            AND selected_intensity IS NULL
            AND explanation IS NULL
            AND response_time_ms IS NULL
            AND timed_out IS NULL
            AND impulsive IS NULL
            AND semantic_error_distance IS NULL)
        OR
        (answered_at IS NOT NULL
            AND selected_emotion_key IS NOT NULL
            AND selected_intensity BETWEEN 0 AND 2
            AND explanation IS NOT NULL
            AND response_time_ms >= 0
            AND timed_out IS NOT NULL
            AND impulsive IS NOT NULL
            AND semantic_error_distance BETWEEN 0.0 AND 1.0));
