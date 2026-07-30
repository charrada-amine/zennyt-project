-- ═══════════════════════════════════════════════════════════════════════════
-- V25 — « Emotional Radar » (GameType EMOTIONAL_REGULATION)
--
-- Cinquième domaine cognitif : régulation émotionnelle. Le candidat observe une
-- scène (dialogue, texte, image ou vidéo), identifie la famille d'émotion, la
-- nuance, puis l'intensité.
--
-- Particularité : c'est le premier jeu dont le CONTENU est servi par le backend.
-- La clé de correction (expected_*) vit exclusivement ici et n'est jamais
-- sérialisée vers le client : la correction se fait scène par scène côté serveur.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Autoriser le nouveau type de jeu et le nouveau mini-jeu ──────────────
-- Les contraintes CHECK de V9 énumèrent les valeurs autorisées : on les remplace
-- (on ne modifie JAMAIS une migration existante, on ajoute une migration).

-- ⚠️ Le nom exact vient de V9 : « ck_game_sessions_type » (et non
-- ck_game_sessions_game_type). Se tromper de nom ferait échouer le DROP en
-- silence (IF EXISTS) et laisserait l'ancienne contrainte refuser le nouveau type.
ALTER TABLE games.game_sessions DROP CONSTRAINT IF EXISTS ck_game_sessions_type;
ALTER TABLE games.game_sessions ADD CONSTRAINT ck_game_sessions_type
    CHECK (game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',
                         'EMOTIONAL_REGULATION'));

ALTER TABLE games.game_attempts DROP CONSTRAINT IF EXISTS ck_game_attempts_mini_game;
ALTER TABLE games.game_attempts ADD CONSTRAINT ck_game_attempts_mini_game
    CHECK (mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING', 'PREVISION_PUZZLE',
                         'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE',
                         'EMOTIONAL_RADAR_CORE'));

-- ── 2. Taxonomie émotion → nuances ──────────────────────────────────────────
-- `source` distingue ce qui vient des maquettes de ce qui est PROVISOIRE
-- (sous-catégories Ekman ajoutées faute de taxonomie fournie). Le psychologue
-- peut ainsi remplacer les seules lignes PROVISIONAL sans toucher aux autres.

CREATE TABLE games.emotional_radar_nuances (
    emotion       VARCHAR(16)  NOT NULL,
    nuance_key    VARCHAR(64)  NOT NULL,
    label         VARCHAR(128) NOT NULL,
    display_order INT          NOT NULL,
    source        VARCHAR(16)  NOT NULL,
    PRIMARY KEY (emotion, nuance_key),
    CONSTRAINT ck_er_nuances_emotion CHECK (
        emotion IN ('JOY', 'SADNESS', 'ANGER', 'FEAR', 'DISGUST', 'SURPRISE')),
    CONSTRAINT ck_er_nuances_source CHECK (source IN ('FIGMA', 'PROVISIONAL'))
);

-- ── 3. Scènes ───────────────────────────────────────────────────────────────

CREATE TABLE games.emotional_radar_scenes (
    id                 UUID         PRIMARY KEY,
    scene_order        INT          NOT NULL,
    media_type         VARCHAR(16)  NOT NULL,
    prompt_text        TEXT         NOT NULL,
    instruction_text   TEXT         NOT NULL,
    media_url          TEXT,
    media_public_id    TEXT,
    alt_text           TEXT,
    transcript         TEXT,
    expected_emotion   VARCHAR(16)  NOT NULL,
    expected_nuance    VARCHAR(64)  NOT NULL,
    expected_intensity INT          NOT NULL,
    explanation        TEXT         NOT NULL,
    active             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_er_scenes_media_type CHECK (
        media_type IN ('DIALOGUE', 'TEXT', 'IMAGE', 'VIDEO')),
    CONSTRAINT ck_er_scenes_emotion CHECK (
        expected_emotion IN ('JOY', 'SADNESS', 'ANGER', 'FEAR', 'DISGUST', 'SURPRISE')),
    CONSTRAINT ck_er_scenes_intensity CHECK (expected_intensity BETWEEN 1 AND 5),
    -- Accessibilité (planche « Accessibility Compliance ») : tout média porte un
    -- équivalent textuel, et la vidéo une transcription. Contrainte doublée dans
    -- le domaine (EmotionalRadarScene) pour ne pas dépendre de la seule base.
    CONSTRAINT ck_er_scenes_alt_text CHECK (
        media_type NOT IN ('IMAGE', 'VIDEO')
        OR (alt_text IS NOT NULL AND alt_text <> '')),
    CONSTRAINT ck_er_scenes_transcript CHECK (
        media_type <> 'VIDEO' OR (transcript IS NOT NULL AND transcript <> ''))
);

CREATE UNIQUE INDEX ux_er_scenes_order ON games.emotional_radar_scenes (scene_order);

-- ── 4. Réponses notées ──────────────────────────────────────────────────────
-- Source de vérité du score. Écrites par le serveur au moment de la validation
-- d'une scène, relues à la soumission finale : un payload client falsifié ne
-- peut donc pas modifier le score (AGENTS.md §7.4).

CREATE TABLE games.emotional_radar_answers (
    session_id         UUID        NOT NULL REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    scene_id           UUID        NOT NULL REFERENCES games.emotional_radar_scenes(id),
    scene_order        INT         NOT NULL,
    selected_emotion   VARCHAR(16) NOT NULL,
    selected_nuance    VARCHAR(64) NOT NULL,
    selected_intensity INT         NOT NULL,
    expected_emotion   VARCHAR(16) NOT NULL,
    expected_nuance    VARCHAR(64) NOT NULL,
    expected_intensity INT         NOT NULL,
    emotion_points     INT         NOT NULL,
    nuance_points      INT         NOT NULL,
    intensity_points   INT         NOT NULL,
    scene_points       INT         NOT NULL,
    correct            BOOLEAN     NOT NULL,
    answered_at        TIMESTAMPTZ NOT NULL,
    -- Une seule réponse par (session, scène) : re-valider après une coupure
    -- réseau remplace la ligne au lieu de doubler les points.
    PRIMARY KEY (session_id, scene_id),
    CONSTRAINT ck_er_answers_intensity CHECK (selected_intensity BETWEEN 1 AND 5),
    CONSTRAINT ck_er_answers_points CHECK (
        emotion_points BETWEEN 0 AND 3
        AND nuance_points BETWEEN 0 AND 4
        AND intensity_points BETWEEN 0 AND 2
        AND scene_points BETWEEN 0 AND 10)
);

CREATE INDEX ix_er_answers_session ON games.emotional_radar_answers (session_id);

-- ── 5. Seed — taxonomie des nuances ─────────────────────────────────────────
-- FIGMA      : lisible sur une planche, fait autorité.
-- PROVISIONAL: sous-catégorie Ekman — ⚠️ à valider par le psychologue.

INSERT INTO games.emotional_radar_nuances (emotion, nuance_key, label, display_order, source) VALUES
    -- SADNESS : liste complète fournie par l'écran « 04 Emotion Selected ».
    ('SADNESS', 'DISAPPOINTMENT', 'Disappointment', 1, 'FIGMA'),
    ('SADNESS', 'NOSTALGIA',      'Nostalgia',      2, 'FIGMA'),
    ('SADNESS', 'EMPATHIC_PAIN',  'Empathic pain',  3, 'FIGMA'),
    ('SADNESS', 'SYMPATHY',       'Sympathy',       4, 'FIGMA'),
    ('SADNESS', 'GUILT',          'Guilt',          5, 'FIGMA'),
    -- FEAR : seule « Anxiety » est attestée (carte de feedback scène 2).
    ('FEAR',    'ANXIETY',        'Anxiety',        1, 'FIGMA'),
    ('FEAR',    'APPREHENSION',   'Apprehension',   2, 'PROVISIONAL'),
    ('FEAR',    'NERVOUSNESS',    'Nervousness',    3, 'PROVISIONAL'),
    ('FEAR',    'DREAD',          'Dread',          4, 'PROVISIONAL'),
    ('FEAR',    'PANIC',          'Panic',          5, 'PROVISIONAL'),
    -- JOY : « Excitement » et « Triumph » attestées sur les cartes de feedback.
    ('JOY',     'EXCITEMENT',     'Excitement',     1, 'FIGMA'),
    ('JOY',     'TRIUMPH',        'Triumph',        2, 'FIGMA'),
    ('JOY',     'CONTENTMENT',    'Contentment',    3, 'PROVISIONAL'),
    ('JOY',     'PRIDE',          'Pride',          4, 'PROVISIONAL'),
    ('JOY',     'RELIEF',         'Relief',         5, 'PROVISIONAL'),
    -- ANGER / DISGUST / SURPRISE : aucune nuance sur les planches.
    ('ANGER',   'IRRITATION',     'Irritation',     1, 'PROVISIONAL'),
    ('ANGER',   'FRUSTRATION',    'Frustration',    2, 'PROVISIONAL'),
    ('ANGER',   'INDIGNATION',    'Indignation',    3, 'PROVISIONAL'),
    ('ANGER',   'RESENTMENT',     'Resentment',     4, 'PROVISIONAL'),
    ('ANGER',   'RAGE',           'Rage',           5, 'PROVISIONAL'),
    ('DISGUST', 'DISTASTE',       'Distaste',       1, 'PROVISIONAL'),
    ('DISGUST', 'AVERSION',       'Aversion',       2, 'PROVISIONAL'),
    ('DISGUST', 'REVULSION',      'Revulsion',      3, 'PROVISIONAL'),
    ('DISGUST', 'CONTEMPT',       'Contempt',       4, 'PROVISIONAL'),
    ('DISGUST', 'DISAPPROVAL',    'Disapproval',    5, 'PROVISIONAL'),
    ('SURPRISE','ASTONISHMENT',   'Astonishment',   1, 'PROVISIONAL'),
    ('SURPRISE','AMAZEMENT',      'Amazement',      2, 'PROVISIONAL'),
    ('SURPRISE','STARTLE',        'Startle',        3, 'PROVISIONAL'),
    ('SURPRISE','CONFUSION',      'Confusion',      4, 'PROVISIONAL'),
    ('SURPRISE','CURIOSITY',      'Curiosity',      5, 'PROVISIONAL');

-- ── 6. Seed — les 3 scènes rédigées ─────────────────────────────────────────
-- Seules scènes dont le contenu est fourni (planche « Developer handoff »).
-- L'UI annonce « Scene N / 15 » mais la planche « Phase 2 QA notes » place le
-- contenu des 15 scènes en Phase 3 : les 12 manquantes ne sont PAS inventées.
--
-- ⚠️ Scène 3 — contradiction Figma tranchée. La table « Phase 2 scene answer
-- data » indique « Joy → Triumph → 4 », mais la planche « Dark Mode Support »
-- ET les deux layouts de « Responsive reimagination » indiquent
-- « Sadness → Empathic pain → 3 », ce dernier précisant : « The scene is
-- interpersonal and silent. The answer should capture sadness observed in
-- someone else. » Trois planches concordantes + justification textuelle
-- l'emportent sur la ligne isolée du tableau.

INSERT INTO games.emotional_radar_scenes
    (id, scene_order, media_type, prompt_text, instruction_text,
     alt_text, expected_emotion, expected_nuance, expected_intensity, explanation) VALUES
    ('a1e5c7d2-0000-4000-8000-000000000001', 1, 'DIALOGUE',
     'Friend: "I am sorry, I have to cancel tonight."',
     'Observe the situation, then identify the emotional pattern.',
     NULL, 'SADNESS', 'DISAPPOINTMENT', 3,
     'Disappointment belongs to the sadness family because the situation involves an unmet expectation.'),
    ('a1e5c7d2-0000-4000-8000-000000000002', 2, 'TEXT',
     'You hear a strange noise at night while alone at home.',
     'Observe the situation, then identify the emotional pattern.',
     NULL, 'FEAR', 'ANXIETY', 4,
     'Anxiety appears when the threat is uncertain, invisible, or not yet confirmed.');

-- Scène 3 : média IMAGE. L'URL est rattachée après téléversement
-- (POST /games/emotional-radar/scenes/{id}/media) ; tant qu'elle est absente la
-- scène reste inactive, la contrainte d'accessibilité exigeant un média présent.
INSERT INTO games.emotional_radar_scenes
    (id, scene_order, media_type, prompt_text, instruction_text,
     alt_text, expected_emotion, expected_nuance, expected_intensity, explanation, active) VALUES
    ('a1e5c7d2-0000-4000-8000-000000000003', 3, 'IMAGE',
     'A child cries alone in a quiet courtyard.',
     'Observe the image, then identify the emotional pattern.',
     'A child crying alone in a quiet courtyard.',
     'SADNESS', 'EMPATHIC_PAIN', 3,
     'Empathic pain is sadness felt for someone else''s distress rather than one''s own.',
     FALSE);
