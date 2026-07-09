-- « J'investigue » (MEMORY_QUEST) — autoriser le mini-jeu MEMORY_QUEST_CORE
-- dans la contrainte CHECK des résultats (Phase 4 : backend + scoring).
ALTER TABLE games.game_attempts
    DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;

ALTER TABLE games.game_attempts
    ADD CONSTRAINT ck_game_attempts_mini_game CHECK (
        mini_game IN (
            'OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
            'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE'
        )
    );
