-- Progression du joueur dans le catalogue des jeux (« Coverage » du hub).
--
-- Une ligne par (joueur, jeu du catalogue) dès la première partie terminée.
-- La couverture affichée est la part des 13 jeux du catalogue présents ici.
-- `game_key` suit l'énumération CatalogGame : Memory Quest y compte pour deux
-- jeux (chiffres, images), contrairement à `game_attempts.mini_game`.

CREATE TABLE IF NOT EXISTS games.player_game_completions (
    player_id          UUID         NOT NULL,
    game_key           VARCHAR(40)  NOT NULL,
    first_completed_at TIMESTAMPTZ  NOT NULL,
    last_completed_at  TIMESTAMPTZ  NOT NULL,
    completion_count   INTEGER      NOT NULL DEFAULT 1,
    PRIMARY KEY (player_id, game_key),
    CONSTRAINT ck_player_game_completions_key CHECK (
        game_key IN (
            'MOVE_FAST', 'CONTINUOUS_ATTENTION', 'COORDINATION_TRACKING',
            'MEMORY_QUEST_DIGITS', 'MEMORY_QUEST_IMAGES', 'OBJECT_LOCATION',
            'DECISION', 'OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREDICTIVE_PUZZLE',
            'EMOTIONAL_RADAR', 'REFLECTIVE_PAUSE', 'STRATEGIC_CHOICES'
        )
    ),
    CONSTRAINT ck_player_game_completions_count CHECK (completion_count >= 1)
);

-- Reprise de l'historique : les parties déjà enregistrées comptent.
--
-- Memory Quest est volontairement exclu : son mode (chiffres, images ou
-- complet) n'a jamais été conservé, on ne peut donc pas dire quel jeu du
-- catalogue une ancienne partie a terminé. Ces jeux se valideront à la
-- prochaine partie.
INSERT INTO games.player_game_completions (
    player_id, game_key, first_completed_at, last_completed_at, completion_count
)
SELECT s.player_id,
       CASE a.mini_game
           WHEN 'MOVE_FAST_CORE'               THEN 'MOVE_FAST'
           WHEN 'CONTINUOUS_ATTENTION_CORE'    THEN 'CONTINUOUS_ATTENTION'
           WHEN 'COORDINATION_TRACKING_CORE'   THEN 'COORDINATION_TRACKING'
           WHEN 'OBJECT_LOCATION_BINDING_CORE' THEN 'OBJECT_LOCATION'
           WHEN 'DECISION_CORE'                THEN 'DECISION'
           WHEN 'OPTIMAL_PATH'                 THEN 'OPTIMAL_PATH'
           WHEN 'TASK_SCHEDULING'              THEN 'TASK_SCHEDULING'
           WHEN 'PREVISION_PUZZLE'             THEN 'PREDICTIVE_PUZZLE'
           WHEN 'EMOTIONAL_RADAR_CORE'         THEN 'EMOTIONAL_RADAR'
           WHEN 'REFLECTIVE_PAUSE_CORE'        THEN 'REFLECTIVE_PAUSE'
           WHEN 'STRATEGIC_CHOICES_CORE'       THEN 'STRATEGIC_CHOICES'
       END,
       MIN(a.recorded_at),
       MAX(a.recorded_at),
       COUNT(*)
FROM games.game_attempts a
JOIN games.game_sessions s ON s.id = a.session_id
WHERE a.mini_game <> 'MEMORY_QUEST_CORE'
GROUP BY s.player_id, 2
ON CONFLICT (player_id, game_key) DO NOTHING;

-- Radar émotionnel v2 : le parcours ne crée pas d'Attempt en phase A. Une
-- session dont les 15 scènes ont reçu une réponse est une partie terminée.
INSERT INTO games.player_game_completions (
    player_id, game_key, first_completed_at, last_completed_at, completion_count
)
SELECT s.player_id, 'EMOTIONAL_RADAR', MIN(done.finished_at),
       MAX(done.finished_at), COUNT(*)
FROM (
    SELECT session_id, MAX(answered_at) AS finished_at
    FROM games.emotional_radar_v2_scenes
    WHERE answered_at IS NOT NULL
    GROUP BY session_id
    HAVING COUNT(*) = 15
) done
JOIN games.game_sessions s ON s.id = done.session_id
GROUP BY s.player_id
ON CONFLICT (player_id, game_key) DO UPDATE SET
    first_completed_at = LEAST(
        games.player_game_completions.first_completed_at,
        EXCLUDED.first_completed_at),
    last_completed_at = GREATEST(
        games.player_game_completions.last_completed_at,
        EXCLUDED.last_completed_at),
    completion_count = games.player_game_completions.completion_count
        + EXCLUDED.completion_count;
