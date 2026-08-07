-- "Recommended for you" (filtrage de pertinence) — préférences de recherche
-- d'emploi du candidat, projetées depuis Identity (voir
-- UserAccessStateChangedEvent). Toujours NULL pour un recruteur, ou si le
-- candidat n'a pas renseigné le critère — jamais un filtre bloquant.
ALTER TABLE recruitment.actors
    ADD COLUMN workplace_type_preference VARCHAR(20),
    ADD COLUMN contract_type_preference VARCHAR(20),
    ADD COLUMN target_location VARCHAR(255),
    ADD COLUMN open_internationally BOOLEAN,
    ADD COLUMN years_of_experience INT,
    ADD COLUMN looking_for TEXT,
    ADD COLUMN looking_for_embedding TEXT;
