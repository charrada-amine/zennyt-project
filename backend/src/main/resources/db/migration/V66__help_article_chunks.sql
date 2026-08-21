-- Fragments d'articles et leurs empreintes numeriques (etape 3).
--
-- Pourquoi decouper : un article entier repond mal a une question precise. « Pourquoi mon
-- score a change ? » doit ramener le paragraphe sur le recalcul, pas les six paragraphes
-- de l'article. Un fragment cible se cite, un article entier se resume — et resumer, c'est
-- deja reecrire.
CREATE TABLE engagement.help_article_chunks (
    id            UUID PRIMARY KEY,
    article_id    UUID        NOT NULL REFERENCES engagement.help_articles(id) ON DELETE CASCADE,
    position      INT         NOT NULL,
    text          TEXT        NOT NULL,
    -- Empreinte stockee en JSON dans une colonne texte, comme les metiers du referentiel.
    -- Le meme arbitrage tient : quelques centaines de fragments se comparent en memoire
    -- sans peine, et une extension Postgres dediee serait une dependance de plus a
    -- installer partout pour un gain nul a cette echelle.
    embedding     TEXT,
    -- Empreinte du TEXTE du fragment. Elle dit si l'empreinte numerique doit etre
    -- recalculee : sans elle, un redemarrage rappellerait le service pour chaque fragment.
    source_hash   TEXT        NOT NULL,
    CONSTRAINT help_chunks_article_position_unique UNIQUE (article_id, position)
);

CREATE INDEX idx_engagement_help_chunks_article ON engagement.help_article_chunks (article_id);

-- Retrouver les fragments dont l'empreinte manque encore, pour les rattraper en tache de
-- fond sans balayer toute la table.
CREATE INDEX idx_engagement_help_chunks_sans_empreinte
    ON engagement.help_article_chunks (id) WHERE embedding IS NULL;

COMMENT ON COLUMN engagement.help_article_chunks.embedding IS
    'Empreinte semantique du fragment, ou NULL si le service n''est pas configure —
     la recherche bascule alors sur les mots, jamais sur rien.';
