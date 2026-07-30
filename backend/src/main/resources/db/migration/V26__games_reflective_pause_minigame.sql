-- V26 — « Reflective Pause » (2e mini-jeu de EMOTIONAL_REGULATION).
--
-- Aucune table dédiée : les métriques brutes sont notées à la soumission puis
-- le Score /10 est persisté comme un Attempt. On étend uniquement la contrainte
-- créée par V25, sans modifier l'historique des migrations.

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE'));
