-- « Je Décide » (DECISION) — autoriser le mini-jeu DECISION_CORE dans la
-- contrainte CHECK des résultats. Le GameType DECISION est déjà autorisé
-- (ck_game_sessions_type, V9) ; seul le mini-jeu manquait au CHECK des attempts.
-- Aucune nouvelle table : le score agrégé (SCW /100) est un simple Attempt.
ALTER TABLE games.game_attempts
    DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;

ALTER TABLE games.game_attempts
    ADD CONSTRAINT ck_game_attempts_mini_game CHECK (
        mini_game IN (
            'OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
            'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE'
        )
    );
