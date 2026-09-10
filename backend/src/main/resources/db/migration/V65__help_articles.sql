-- Corpus documentaire du centre d'aide (etape 2 du PLAN_HELP_CENTER_AGENT.md).
--
-- Les articles vivent dans des fichiers de ressources, pas dans cette migration : un
-- texte se relit et se corrige en revue, ce qu'une longue suite d'INSERT rend penible.
-- Cette table est la projection de ces fichiers, synchronisee au demarrage.
--
-- Pourquoi une table plutot que la lecture directe des fichiers : l'etape 3 doit
-- attacher une empreinte numerique a chaque fragment, et ne la recalculer que lorsque
-- le texte change. Sans ligne en base, il n'y a rien a quoi rattacher l'empreinte.
CREATE TABLE engagement.help_articles (
    id            UUID PRIMARY KEY,
    slug          TEXT        NOT NULL,
    locale        TEXT        NOT NULL,
    audience      TEXT        NOT NULL,
    category      TEXT        NOT NULL,
    title         TEXT        NOT NULL,
    body          TEXT        NOT NULL,
    -- Empreinte du texte. C'est elle qui dit si un article a change depuis le dernier
    -- demarrage : comparer les dates ne suffirait pas, un fichier peut etre reecrit a
    -- l'identique par un outil de formatage.
    content_hash  TEXT        NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL,
    CONSTRAINT help_articles_slug_locale_unique UNIQUE (slug, locale),
    CONSTRAINT help_articles_audience_valide
        CHECK (audience IN ('CANDIDATE', 'RECRUITER', 'BOTH'))
);

-- La recherche se fera par public : un candidat ne doit pas recevoir un article ecrit
-- pour un recruteur, et inversement.
CREATE INDEX idx_engagement_help_articles_audience
    ON engagement.help_articles (locale, audience);

COMMENT ON TABLE engagement.help_articles IS
    'Documentation destinee aux utilisateurs, source du volet documentaire de l''agent.
     Synchronisee depuis les fichiers de resources au demarrage — ne pas editer a la main.';
COMMENT ON COLUMN engagement.help_articles.audience IS
    'CANDIDATE, RECRUITER ou BOTH — un article de creation d''offre n''a rien a dire a un candidat.';
