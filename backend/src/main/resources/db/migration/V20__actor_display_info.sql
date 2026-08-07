-- Champs d'affichage (nom, avatar, localisation) portés par la projection
-- d'acteurs, propagés depuis Identity via UserAccessStateChangedEvent.
-- Sans eux, les listes candidat/recruteur (deck fit-score, matches) n'ont
-- aucun moyen d'afficher un nom sans dépendre directement du module Identity.
ALTER TABLE recruitment.actors
    ADD COLUMN full_name VARCHAR(200),
    ADD COLUMN avatar_url VARCHAR(500),
    ADD COLUMN city VARCHAR(100),
    ADD COLUMN country VARCHAR(100);
