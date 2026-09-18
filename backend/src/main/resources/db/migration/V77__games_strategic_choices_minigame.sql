-- « Choix Stratégiques » — autoriser le mini-jeu en base.
--
-- La contrainte `ck_game_attempts_mini_game` ÉNUMÈRE les mini-jeux acceptés.
-- Ajouter une valeur à l'énumération Java, au contrat OpenAPI et au barème ne
-- suffit donc pas : sans cette migration, la toute première partie enregistrée
-- échoue en HTTP 500 au moment de l'insertion de la tentative — c'est
-- exactement ce qui s'est produit en vérification.
--
-- Le motif se répète (V62, V63 ont fait de même) : chaque nouveau mini-jeu doit
-- élargir cette liste, faute de quoi il est jouable mais pas enregistrable.

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE', 'REFLECTIVE_PAUSE_CORE',
                         'CONTINUOUS_ATTENTION_CORE',
                         'COORDINATION_TRACKING_CORE',
                         'OBJECT_LOCATION_BINDING_CORE',
                         'STRATEGIC_CHOICES_CORE'));
