-- Notation d'une conversation d'aide (etape 1 du PLAN_HELP_CENTER_AGENT.md).
--
-- L'ecran de notation existait cote mobile depuis la fusion du 15/08 : le dialogue
-- Poor/OK/Great et le formulaire « What can we improve? » etaient dessines, mais le
-- choix de l'utilisateur ne quittait jamais un setState. Rien n'etait envoye, rien
-- n'etait garde.
--
-- La note vit sur la conversation et non sur un message : on note un echange, pas une
-- phrase. Les deux colonnes sont nullables — une conversation non notee est le cas
-- normal, et le commentaire reste facultatif meme quand la note est donnee (le
-- formulaire de commentaire s'ouvre APRES la note, et peut etre ferme).
ALTER TABLE engagement.help_chats
    ADD COLUMN rating        TEXT,
    ADD COLUMN rating_comment TEXT,
    ADD COLUMN rated_at      TIMESTAMPTZ;

-- Les trois valeurs de la maquette, et rien d'autre. Une contrainte plutot qu'un
-- simple commentaire : c'est ce qui empeche un client mal aligne d'ecrire « great »
-- ou « 5 » et de rendre les statistiques inexploitables plus tard.
ALTER TABLE engagement.help_chats
    ADD CONSTRAINT help_chats_rating_valide
    CHECK (rating IS NULL OR rating IN ('POOR', 'OK', 'GREAT'));

-- La date n'a de sens qu'avec une note, et inversement : les deux se posent d'un seul
-- geste. Sans cette contrainte, une ligne notee sans date passerait inapercue et
-- fausserait tout calcul de delai entre l'echange et son evaluation.
ALTER TABLE engagement.help_chats
    ADD CONSTRAINT help_chats_rating_date_coherente
    CHECK ((rating IS NULL) = (rated_at IS NULL));

COMMENT ON COLUMN engagement.help_chats.rating IS
    'Appreciation de l''utilisateur sur l''echange : POOR, OK ou GREAT.';
COMMENT ON COLUMN engagement.help_chats.rating_comment IS
    'Commentaire libre facultatif, saisi apres la note.';
