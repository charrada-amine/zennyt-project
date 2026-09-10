-- « Je Décide » — catalogue des 120 scénarios en base.
--
-- Jusqu'ici la banque du psychologue vivait en ressource JSON, lue au
-- démarrage par JsonDecisionScenarioCatalog. Elle passe en base pour que le
-- contenu (vignettes, énoncés d'options) puisse être SERVI au client, ce que
-- le port de scoring ne permet pas : son record Item ne porte que
-- (dimension, format, qualité par option). Le JSON reste dans le dépôt comme
-- SOURCE DU SEED (traçabilité Git) ; il n'est plus lu à l'exécution.
--
-- Banque = 120 items (24 par dimension). Passation = 30 items
-- (DecisionConfig.ITEMS_PER_DIMENSION = 6). La composition d'une forme est
-- une DONNÉE (table decision_form_items), pas une règle positionnelle :
--   • les paires CS (CS-1a/CS-1b…) doivent rester ensemble — une règle
--     positionnelle par modulo les casserait ;
--   • ER-1..18, CS et RE sont en notation neutre provisoire, donc un
--     découpage positionnel produirait des formes NON équivalentes (la seule
--     forme contenant ER-19..24 serait la seule où ER discrimine).
-- Une seule forme (A) est donc seedée ici. B/C/D seront ajoutées par une
-- migration ultérieure, quand le modèle λ/k/cohérence rendra ER, CS et RE
-- discriminants et la question de l'équivalence des formes soluble.

-- ── 1. Scénarios ────────────────────────────────────────────────────────────

CREATE TABLE games.decision_scenarios (
    id                  UUID         PRIMARY KEY,
    item_id             VARCHAR(20)  NOT NULL,
    dimension           VARCHAR(2)   NOT NULL,
    format              VARCHAR(20)  NOT NULL,
    -- Identifiant de paire (CS-1 pour CS-1a + CS-1b). NULL hors COHERENCE_PAIR.
    -- Indispensable au futur modèle de cohérence : les deux cadrages (gain /
    -- perte) n'ont de sens qu'appariés.
    pair_id             VARCHAR(20),
    -- Un item porte SOIT sa vignette, SOIT une référence vers celle d'un autre
    -- item : les 24 items DT réutilisent la vignette de leur II homologue
    -- (DT-1 → II-1), présentée cette fois sous contrainte de 7 secondes.
    vignette            TEXT,
    vignette_ref        VARCHAR(20),
    task                TEXT         NOT NULL,
    optimal_option      VARCHAR(40),
    -- true → l'item est en notation NEUTRE provisoire (toutes ses options à
    -- SATISFACTORY). Colonne et non commentaire : le jour où le vrai modèle
    -- arrive, c'est la requête qui dit quoi recalculer.
    provisional_scoring BOOLEAN      NOT NULL,
    position            INT          NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ux_decision_scenarios_item UNIQUE (item_id),
    CONSTRAINT ck_decision_scenarios_dimension CHECK (
        dimension IN ('II', 'ER', 'DT', 'CS', 'RE')),
    CONSTRAINT ck_decision_scenarios_format CHECK (
        format IN ('STANDARD', 'TEMPORAL_DECISION', 'COHERENCE_PAIR')),
    CONSTRAINT ck_decision_scenarios_pair CHECK (
        (format = 'COHERENCE_PAIR') = (pair_id IS NOT NULL)),
    -- Vignette propre OU référencée, jamais les deux ni aucune.
    CONSTRAINT ck_decision_scenarios_vignette CHECK (
        (vignette IS NOT NULL) <> (vignette_ref IS NOT NULL)),
    CONSTRAINT ck_decision_scenarios_position CHECK (position >= 1)
);

CREATE INDEX ix_decision_scenarios_dimension
    ON games.decision_scenarios (dimension, position);

-- ── 2. Options ──────────────────────────────────────────────────────────────
-- `quality` est l'unique clé de correction. Le score /3 n'est PAS dupliqué
-- ici : il est porté par OptionQuality.points() côté domaine, et une seconde
-- source de vérité ne pourrait que diverger.

CREATE TABLE games.decision_scenario_options (
    id          UUID         PRIMARY KEY,
    scenario_id UUID         NOT NULL
                REFERENCES games.decision_scenarios(id) ON DELETE CASCADE,
    option_id   VARCHAR(40)  NOT NULL,
    label       TEXT         NOT NULL,
    quality     VARCHAR(16)  NOT NULL,
    position    INT          NOT NULL,
    CONSTRAINT ux_decision_options_code UNIQUE (scenario_id, option_id),
    CONSTRAINT ck_decision_options_quality CHECK (
        quality IN ('OPTIMAL', 'SATISFACTORY', 'PARTIAL', 'DEFICIENT')),
    CONSTRAINT ck_decision_options_position CHECK (position >= 1)
);

CREATE INDEX ix_decision_options_scenario
    ON games.decision_scenario_options (scenario_id, position);

-- ── 3. Composition des formes parallèles ────────────────────────────────────

CREATE TABLE games.decision_form_items (
    -- VARCHAR et non CHAR : Postgres traite CHAR(1) comme `bpchar`, avec un
    -- remplissage par espaces dont on n'a aucun besoin — et Hibernate valide un
    -- String mappé comme varchar, donc CHAR ferait échouer le démarrage.
    form_code   VARCHAR(1) NOT NULL,
    scenario_id UUID     NOT NULL
                REFERENCES games.decision_scenarios(id) ON DELETE RESTRICT,
    position    INT      NOT NULL,
    PRIMARY KEY (form_code, scenario_id),
    CONSTRAINT ux_decision_form_position UNIQUE (form_code, position),
    CONSTRAINT ck_decision_form_code CHECK (form_code IN ('A', 'B', 'C', 'D')),
    CONSTRAINT ck_decision_form_position CHECK (position BETWEEN 1 AND 30)
);

-- ── 4. Forme assignée à la session ──────────────────────────────────────────
-- Sur la SESSION, pas sur l'attempt : l'attempt n'est écrit qu'à la
-- soumission, alors que la forme est tirée à la création de session et doit
-- être relue par GET /decision/items puis à la notation.
-- Nullable : les sessions non-DECISION n'en ont pas.

ALTER TABLE games.game_sessions
    ADD COLUMN decision_form_code VARCHAR(1);

ALTER TABLE games.game_sessions
    ADD CONSTRAINT ck_game_sessions_decision_form CHECK (
        decision_form_code IS NULL OR decision_form_code IN ('A', 'B', 'C', 'D'));

-- ── 5. Seed — banque complète (120 items), généré depuis
--    resources/games/decision_scenarios.json ─────────────────────────────────

INSERT INTO games.decision_scenarios
    (id, item_id, dimension, format, pair_id, vignette, vignette_ref, task,
     optimal_option, provisional_scoring, position)
VALUES
    ('d93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1', 'II', 'STANDARD', NULL, $t$Vous préparez un déplacement professionnel. Trois hôtels : A (prix bas, à 30 min à pied du lieu de rendez-vous, avis mixtes), B (prix moyen, à 8 min à pied, bonnes notes), C (cher, dépassant votre budget, à 5 min, note excellente). Votre budget ne doit pas dépasser le tarif moyen et le trajet ne doit pas excéder 10 minutes à pied.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 1),
    ('3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2', 'II', 'STANDARD', NULL, $t$Vous choisissez un smartphone pour un usage professionnel avec déplacements fréquents. Trois modèles : A (prix moyen, autonomie 2 jours, design correct), B (prix bas, autonomie 1 jour, bonnes critiques), C (cher, dépassant votre budget, autonomie 3 jours). Budget limité, autonomie ≥ 2 jours requise.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 2),
    ('33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3', 'II', 'STANDARD', NULL, $t$Vous cherchez un appartement à louer. Trois options : A (loyer dans le plafond, trajet 25 min, quartier calme), B (loyer bas, trajet 50 min, quartier très calme), C (loyer élevé, dépassant votre plafond, trajet 10 min, quartier animé). Plafond de loyer fixe, trajet ≤ 30 min exigé. Le calme du quartier est un critère secondaire non éliminatoire.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 3),
    ('87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4', 'II', 'STANDARD', NULL, $t$Vous recevez trois offres d'emploi : A (CDI, salaire légèrement sous votre seuil minimum), B (CDD 18 mois, salaire 15% au-dessus de votre seuil, secteur porteur), C (CDI, salaire au seuil exact, poste avec perspectives d'évolution mentionnées dans l'offre). Priorité à la stabilité contractuelle ; le salaire doit atteindre le seuil minimum.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 4),
    ('715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5', 'II', 'STANDARD', NULL, $t$Vous organisez un repas d'affaires. Trois restaurants : A (cher, hors budget, ambiance calme, note 4.8/5), B (pas cher, dans le budget, très bruyant, note 4.5/5), C (prix dans le budget, ambiance calme, note 4.2/5). Budget plafonné ; conversation professionnelle requérant calme.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 5),
    ('94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6', 'II', 'STANDARD', NULL, $t$Vous choisissez une mutuelle santé. Trois offres : A (prime élevée, hors budget, couverture complète), B (prime basse, dans le budget, couverture insuffisante pour un antécédent médical connu), C (prime dans le budget, couverture adaptée à l'antécédent, délai de remboursement 30 jours). Budget serré ; couverture de l'antécédent obligatoire.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 6),
    ('4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7', 'II', 'STANDARD', NULL, $t$Vous achetez une voiture pour des trajets professionnels réguliers de 250 km. Trois modèles : A (dans le budget, autonomie 550 km, consommation standard), B (moins cher, autonomie 280 km, faible consommation), C (cher, hors budget, autonomie 700 km, faible consommation). Budget plafonné ; autonomie ≥ 500 km requise pour les trajets sans rechargement.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 7),
    ('bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8', 'II', 'STANDARD', NULL, $t$Vous cherchez une crèche pour votre enfant. Trois options : A (tarif bas, horaires 9h–17h, projet pédagogique bilingue), B (tarif dans le budget, horaires 7h30–19h, projet pédagogique standard), C (tarif élevé, hors budget, horaires 7h–20h, projet pédagogique bilingue). Budget plafonné ; horaires devant couvrir 8h–18h30.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 8),
    ('6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9', 'II', 'STANDARD', NULL, $t$Vous choisissez une salle de sport. Trois options : A (moins chère, à 40 min de trajet, équipements récents), B (chère, hors budget, à 5 min, équipements récents), C (dans le budget, à 12 min, équipements corrects). Budget plafonné ; distance ≤ 15 min.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 9),
    ('34e56502-0331-5190-a2d9-3dde31752808', 'II-10', 'II', 'STANDARD', NULL, $t$Vous sélectionnez un logiciel de gestion de projet pour votre équipe de 12 personnes. Trois options : A (moins cher, incompatible avec votre messagerie et votre CRM actuels), B (licence dans le budget, compatible avec la messagerie uniquement), C (prix dans le budget, compatible messagerie et CRM). Budget plafonné ; compatibilité totale avec l'environnement existant requise.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 10),
    ('bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11', 'II', 'STANDARD', NULL, $t$Vous sélectionnez un fournisseur pour un contrat annuel. Trois options : A (tarif bas, délai livraison 18 jours, certifié ISO 9001), B (cher, hors budget, délai 3 jours, certifié ISO 9001), C (dans le budget, délai 6 jours, en cours de certification ISO). Budget plafonné ; délai ≤ 7 jours exigé contractuellement.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 11),
    ('72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12', 'II', 'STANDARD', NULL, $t$Vous choisissez une formation professionnelle certifiante. Trois options : A (moins chère, format journée incompatible avec votre emploi du temps, reconnue par votre secteur), B (tarif dans le budget, format soirée compatible, reconnaissance sectorielle identique à A), C (chère, hors budget, format soirée, reconnue internationalement). Budget plafonné ; format compatible avec emploi du temps actuel.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 12),
    ('0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13', 'II', 'STANDARD', NULL, $t$Vous choisissez un déménageur. Trois options : A (tarif dans le budget, assurance couvrant la valeur totale des biens, disponible dans 2 semaines), B (moins cher, assurance plafonnée à 50% de la valeur des biens, disponible immédiatement), C (cher, hors budget, assurance totale, disponible la semaine prochaine). Budget plafonné ; assurance couvrant 100% de la valeur obligatoire.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 13),
    ('a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14', 'II', 'STANDARD', NULL, $t$Vous choisissez un forfait internet pour le télétravail intensif (visioconférences quotidiennes, transferts de fichiers lourds). Trois options : A (moins cher, débit moyen 20 Mb/s, suffisant pour la navigation mais insuffisant pour la visio HD), B (tarif dans le budget, débit 100 Mb/s, compatible visio HD), C (cher, hors budget, débit 500 Mb/s, fibre optique). Budget plafonné ; débit ≥ 50 Mb/s requis pour les usages professionnels.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 14),
    ('c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15', 'II', 'STANDARD', NULL, $t$Vous choisissez un espace de coworking pour votre équipe de 4 personnes. Trois options : A (moins cher, open space uniquement, pas de salle de réunion réservable), B (cher, hors budget, salles privatives réservables, accès 24h/24), C (dans le budget, salles de réunion réservables 4h/semaine incluses, accès standard 8h–20h). Budget plafonné ; au moins une salle de réunion réservable requise hebdomadairement.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 15),
    ('f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16', 'II', 'STANDARD', NULL, $t$Vous choisissez un traiteur pour un séminaire d'entreprise (80 personnes, dont 12 avec allergies au gluten et 5 végétariens). Trois options : A (moins cher, menus standards, pas d'option sans gluten ni végétarienne), B (dans le budget, menus adaptés gluten et végétarien, service assis), C (cher, hors budget, menus gastronomiques avec toutes adaptations, service à table). Budget plafonné ; menus adaptés obligatoires pour l'ensemble des régimes présents.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 16),
    ('64b551c7-e5af-5465-ae08-c936819eb146', 'II-17', 'II', 'STANDARD', NULL, $t$Vous réservez une salle pour une conférence annuelle (140 participants). Trois options : A (dans le budget, capacité 150 personnes, équipement audiovisuel standard, parking 30 places), B (moins cher, capacité 90 personnes, bon équipement AV, proche transports en commun), C (cher, hors budget, capacité 250 personnes, équipement AV haut de gamme, parking 100 places). Budget plafonné ; capacité ≥ 140 personnes obligatoire.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 17),
    ('d7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18', 'II', 'STANDARD', NULL, $t$Vous choisissez un ordinateur portable pour un graphiste de votre équipe (travail sur logiciels de retouche photo et montage vidéo). Trois options : A (moins cher, RAM 8 Go, GPU intégré, performances insuffisantes pour le montage vidéo 4K), B (dans le budget, RAM 16 Go, GPU dédié 4 Go, compatible avec les logiciels métiers), C (cher, hors budget, RAM 32 Go, GPU dédié 8 Go, performances maximales). Budget plafonné ; performances compatibles avec les logiciels métiers obligatoires.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 18),
    ('0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19', 'II', 'STANDARD', NULL, $t$Vous cherchez un local commercial pour ouvrir un cabinet paramédical recevant du public à mobilité réduite. Trois locaux : A (loyer dans votre budget, accès de plain-pied avec rampe PMR conforme), B (loyer moins cher, accès par un escalier de 3 marches, aucune rampe), C (loyer élevé, dépasse votre budget, accès PMR conforme avec ascenseur). Votre budget est plafonné et l'accessibilité PMR est une obligation réglementaire pour votre activité.$t$, NULL, $t$Classez les trois locaux du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 19),
    ('dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20', 'II', 'STANDARD', NULL, $t$Vous devez louer un camion pour un déménagement professionnel. Trois véhicules : A (tarif dans votre budget, nécessite un permis B classique que vous détenez), B (moins cher, nécessite un permis C1 que vous ne détenez pas), C (cher, dépasse votre budget, nécessite un permis B classique). Votre budget est plafonné et vous ne pouvez conduire qu'avec le permis B que vous détenez.$t$, NULL, $t$Classez les trois véhicules du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 20),
    ('27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21', 'II', 'STANDARD', NULL, $t$Vous cherchez une pension pour votre chien pendant vos vacances. Trois options : A (moins chère, pas de vétérinaire sur place), B (chère, dépasse votre budget, vétérinaire sur place), C (tarif dans votre budget, vétérinaire sur place). Votre budget est plafonné et un vétérinaire doit être disponible sur place en raison d'un traitement médical en cours.$t$, NULL, $t$Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 21),
    ('64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22', 'II', 'STANDARD', NULL, $t$Vous choisissez un fournisseur d'électricité pour votre entreprise. Trois offres : A (tarif dans votre budget, électricité certifiée 100 % renouvelable), B (chère, dépasse votre budget, électricité certifiée 100 % renouvelable), C (moins chère, électricité non certifiée renouvelable). Votre budget est plafonné et la certification 100 % renouvelable est exigée par votre charte RSE.$t$, NULL, $t$Classez les trois offres de la plus à la moins adaptée, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 22),
    ('a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23', 'II', 'STANDARD', NULL, $t$Vous cherchez un avocat pour un litige commercial complexe. Trois cabinets : A (honoraires dans votre budget, spécialisé en droit commercial), B (moins cher, généraliste sans spécialisation en droit commercial), C (cher, dépasse votre budget, spécialisé en droit commercial). Votre budget est plafonné et la spécialisation en droit commercial est indispensable pour ce dossier.$t$, NULL, $t$Classez les trois cabinets du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 23),
    ('e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24', 'II', 'STANDARD', NULL, $t$Vous choisissez un prestataire pour le nettoyage de vos entrepôts en hauteur. Trois prestataires : A (tarif dans votre budget, équipe habilitée travail en hauteur), B (moins cher, équipe non habilitée travail en hauteur), C (cher, dépasse votre budget, équipe habilitée travail en hauteur). Votre budget est plafonné et l'habilitation travail en hauteur est une obligation légale pour cette prestation.$t$, NULL, $t$Classez les trois prestataires du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.$t$, NULL, FALSE, 24),
    ('ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1', 'ER', 'STANDARD', NULL, $t$Option X : 50 € garantis. Option Y : 60 % de chance de gagner 90 €, 40 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 1),
    ('3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2', 'ER', 'STANDARD', NULL, $t$Option X : 30 € garantis. Option Y : 50 % de chance de gagner 70 €, 50 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 2),
    ('ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 50 €. Option Y : 50 % de chance de perdre 120 €, 50 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 3),
    ('524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4', 'ER', 'STANDARD', NULL, $t$Option X : 100 € garantis. Option Y : 25 % de chance de gagner 450 €, 75 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 4),
    ('554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 20 €. Option Y : 50 % de chance de perdre 50 €, 50 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 5),
    ('e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6', 'ER', 'STANDARD', NULL, $t$Option X : 200 € garantis. Option Y : 80 % de chance de gagner 270 €, 20 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 6),
    ('7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7', 'ER', 'STANDARD', NULL, $t$Option X : 40 € garantis. Option Y : 20 % de chance de gagner 250 €, 80 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 7),
    ('bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 80 €. Option Y : 90 % de chance de perdre 100 €, 10 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 8),
    ('8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9', 'ER', 'STANDARD', NULL, $t$Option X : 15 € garantis. Option Y : 50 % de chance de gagner 40 €, 50 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 9),
    ('b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 10 €. Option Y : 50 % de chance de perdre 25 €, 50 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 10),
    ('e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11', 'ER', 'STANDARD', NULL, $t$Option X : 500 € garantis. Option Y : 60 % de chance de gagner 900 €, 40 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 11),
    ('19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 300 €. Option Y : 60 % de chance de perdre 600 €, 40 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 12),
    ('7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13', 'ER', 'STANDARD', NULL, $t$Option X : 25 € garantis. Option Y : 10 % de chance de gagner 300 €, 90 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 13),
    ('e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 5 €. Option Y : 10 % de chance de perdre 60 €, 90 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 14),
    ('037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15', 'ER', 'STANDARD', NULL, $t$Option X : 70 € garantis. Option Y : 50 % de chance de gagner 160 €, 50 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 15),
    ('6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 100 €. Option Y : 50 % de chance de perdre 220 €, 50 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 16),
    ('6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17', 'ER', 'STANDARD', NULL, $t$Option X : 1 000 € garantis. Option Y : 30 % de chance de gagner 4 000 €, 70 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 17),
    ('61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 150 €. Option Y : 30 % de chance de perdre 600 €, 70 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, TRUE, 18),
    ('557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19', 'ER', 'STANDARD', NULL, $t$Option X : 60 € garantis. Option Y : 50 % de chance de gagner 150 €, 50 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 19),
    ('44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 40 €. Option Y : 50 % de chance de perdre 100 €, 50 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 20),
    ('58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21', 'ER', 'STANDARD', NULL, $t$Option X : 120 € garantis. Option Y : 40 % de chance de gagner 350 €, 60 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 21),
    ('e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 60 €. Option Y : 70 % de chance de perdre 100 €, 30 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 22),
    ('67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23', 'ER', 'STANDARD', NULL, $t$Option X : 45 € garantis. Option Y : 25 % de chance de gagner 200 €, 75 % de chance de gagner 0 €.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 23),
    ('9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24', 'ER', 'STANDARD', NULL, $t$Option X : perte certaine de 250 €. Option Y : 40 % de chance de perdre 700 €, 60 % de chance de ne rien perdre.$t$, NULL, $t$Choisissez l'option X ou l'option Y.$t$, NULL, FALSE, 24),
    ('1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-1$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 1),
    ('05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-2$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 2),
    ('b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-3$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 3),
    ('a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-4$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 4),
    ('b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-5$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 5),
    ('f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-6$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 6),
    ('86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-7$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 7),
    ('93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-8$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 8),
    ('0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-9$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 9),
    ('63650717-5648-5191-91c5-244cbaa017f6', 'DT-10', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-10$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 10),
    ('71b34741-0338-5fb6-aade-816894f23a66', 'DT-11', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-11$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 11),
    ('984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-12$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 12),
    ('abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-13$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 13),
    ('6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-14$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 14),
    ('18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-15$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 15),
    ('a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-16$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 16),
    ('d2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-17$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 17),
    ('a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-18$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 18),
    ('785021ff-1130-5225-ae9a-0290603803aa', 'DT-19', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-19$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 19),
    ('7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-20$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 20),
    ('079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-21$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 21),
    ('a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-22$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$B$t$, FALSE, 22),
    ('704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-23$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$A$t$, FALSE, 23),
    ('ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24', 'DT', 'TEMPORAL_DECISION', NULL, NULL, $t$II-24$t$, $t$Vous disposez de 7 secondes pour choisir l'option A, B ou C.$t$, $t$C$t$, FALSE, 24),
    ('11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a', 'CS', 'COHERENCE_PAIR', $t$CS-1$t$, $t$CS-1a — Cadrage GAIN
Plan A : 200 emplois sauvés de façon certaine.
Plan B : 1 chance sur 3 que les 600 emplois soient sauvés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 1),
    ('2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b', 'CS', 'COHERENCE_PAIR', $t$CS-1$t$, $t$CS-1b — Cadrage PERTE
Plan A : 400 emplois perdus de façon certaine.
Plan B : 1 chance sur 3 qu'aucun emploi ne soit perdu, 2 chances sur 3 que les 600 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 2),
    ('de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a', 'CS', 'COHERENCE_PAIR', $t$CS-2$t$, $t$CS-2a — Cadrage GAIN
Option A : conserver 7 000 € de façon certaine.
Option B : 70 % de chance de conserver les 10 000 €, 30 % de chance de tout perdre.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 3),
    ('577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b', 'CS', 'COHERENCE_PAIR', $t$CS-2$t$, $t$CS-2b — Cadrage PERTE
Option A : perdre 3 000 € de façon certaine.
Option B : 70 % de chance de ne rien perdre, 30 % de chance de tout perdre.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 4),
    ('f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a', 'CS', 'COHERENCE_PAIR', $t$CS-3$t$, $t$CS-3a — Cadrage GAIN
Plan A : 300 employés préservent leur santé de façon certaine.
Plan B : 1 chance sur 3 que les 900 soient préservés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 5),
    ('91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b', 'CS', 'COHERENCE_PAIR', $t$CS-3$t$, $t$CS-3b — Cadrage PERTE
Plan A : la santé de 600 employés se dégradera de façon certaine.
Plan B : 1 chance sur 3 qu'aucun employé ne soit affecté, 2 chances sur 3 que les 900 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 6),
    ('38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a', 'CS', 'COHERENCE_PAIR', $t$CS-4$t$, $t$CS-4a — Cadrage GAIN
Plan A : 100 accidents évités de façon certaine.
Plan B : 1 chance sur 3 d'éviter les 300 accidents, 2 chances sur 3 de n'en éviter aucun.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 7),
    ('308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b', 'CS', 'COHERENCE_PAIR', $t$CS-4$t$, $t$CS-4b — Cadrage PERTE
Plan A : 200 accidents surviendront de façon certaine.
Plan B : 1 chance sur 3 qu'aucun accident ne survienne, 2 chances sur 3 que les 300 surviennent.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 8),
    ('9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a', 'CS', 'COHERENCE_PAIR', $t$CS-5$t$, $t$CS-5a — Cadrage GAIN
Plan A : 30 salariés seront formés de façon certaine.
Plan B : 1 chance sur 3 que les 90 soient formés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 9),
    ('b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b', 'CS', 'COHERENCE_PAIR', $t$CS-5$t$, $t$CS-5b — Cadrage PERTE
Plan A : 60 salariés resteront sans formation de façon certaine.
Plan B : 1 chance sur 3 que tous soient formés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 10),
    ('bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a', 'CS', 'COHERENCE_PAIR', $t$CS-6$t$, $t$CS-6a — Cadrage GAIN
Plan A : 300 tonnes préservées de façon certaine.
Plan B : 1 chance sur 3 de préserver les 900 tonnes, 2 chances sur 3 de n'en préserver aucune.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 11),
    ('7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b', 'CS', 'COHERENCE_PAIR', $t$CS-6$t$, $t$CS-6b — Cadrage PERTE
Plan A : 600 tonnes perdues de façon certaine.
Plan B : 1 chance sur 3 qu'aucune tonne ne soit perdue, 2 chances sur 3 que les 900 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 12),
    ('4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a', 'CS', 'COHERENCE_PAIR', $t$CS-7$t$, $t$CS-7a — Cadrage GAIN
Plan A : 300 hectares préservés de façon certaine.
Plan B : 1 chance sur 3 de préserver les 900 hectares, 2 chances sur 3 de n'en préserver aucun.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 13),
    ('e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b', 'CS', 'COHERENCE_PAIR', $t$CS-7$t$, $t$CS-7b — Cadrage PERTE
Plan A : 600 hectares dégradés de façon certaine.
Plan B : 1 chance sur 3 qu'aucun hectare ne soit dégradé, 2 chances sur 3 que les 900 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 14),
    ('1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a', 'CS', 'COHERENCE_PAIR', $t$CS-8$t$, $t$CS-8a — Cadrage GAIN
Plan A : 30 000 € préservés de façon certaine.
Plan B : 1 chance sur 3 de préserver les 90 000 €, 2 chances sur 3 de tout perdre.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 15),
    ('8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b', 'CS', 'COHERENCE_PAIR', $t$CS-8$t$, $t$CS-8b — Cadrage PERTE
Plan A : perdre 60 000 € de façon certaine.
Plan B : 1 chance sur 3 de ne rien perdre, 2 chances sur 3 de tout perdre.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 16),
    ('364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a', 'CS', 'COHERENCE_PAIR', $t$CS-9$t$, $t$CS-9a — Cadrage GAIN
Plan A : 300 salariés protégés de façon certaine.
Plan B : 1 chance sur 3 de protéger les 900 salariés, 2 chances sur 3 de n'en protéger aucun.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 17),
    ('da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b', 'CS', 'COHERENCE_PAIR', $t$CS-9$t$, $t$CS-9b — Cadrage PERTE
Plan A : 600 salariés touchés de façon certaine.
Plan B : 1 chance sur 3 qu'aucun salarié ne soit touché, 2 chances sur 3 que les 900 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 18),
    ('5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a', 'CS', 'COHERENCE_PAIR', $t$CS-10$t$, $t$CS-10a — Cadrage GAIN
Plan A : 60 000 dossiers clients seront protégés de façon certaine.
Plan B : 1 chance sur 3 que les 180 000 dossiers soient protégés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 19),
    ('07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b', 'CS', 'COHERENCE_PAIR', $t$CS-10$t$, $t$CS-10b — Cadrage PERTE
Plan A : 120 000 dossiers clients seront compromis de façon certaine.
Plan B : 1 chance sur 3 qu'aucun dossier ne soit compromis, 2 chances sur 3 que les 180 000 le soient.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 20),
    ('e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a', 'CS', 'COHERENCE_PAIR', $t$CS-11$t$, $t$CS-11a — Cadrage GAIN
Plan A : 80 élèves réussiront leur année de façon certaine.
Plan B : 1 chance sur 3 que les 240 élèves réussissent, 2 chances sur 3 qu'aucun ne réussisse.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 21),
    ('1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b', 'CS', 'COHERENCE_PAIR', $t$CS-11$t$, $t$CS-11b — Cadrage PERTE
Plan A : 160 élèves sur 240 échoueront leur année de façon certaine.
Plan B : 1 chance sur 3 qu'aucun élève n'échoue, 2 chances sur 3 que les 240 échouent.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 22),
    ('554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a', 'CS', 'COHERENCE_PAIR', $t$CS-12$t$, $t$CS-12a — Cadrage GAIN
Plan A : 100 000 foyers seront épargnés par la coupure de façon certaine.
Plan B : 1 chance sur 3 que les 300 000 foyers soient épargnés, 2 chances sur 3 qu'aucun ne le soit.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 23),
    ('908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b', 'CS', 'COHERENCE_PAIR', $t$CS-12$t$, $t$CS-12b — Cadrage PERTE
Plan A : 200 000 foyers sur 300 000 subiront une coupure de façon certaine.
Plan B : 1 chance sur 3 qu'aucun foyer ne subisse de coupure, 2 chances sur 3 que les 300 000 la subissent.$t$, NULL, $t$Choisissez le Plan A ou le Plan B.$t$, NULL, TRUE, 24),
    ('14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1', 'RE', 'STANDARD', NULL, $t$Option immédiate : 10 € maintenant. Option différée : 25 € dans 7 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 1),
    ('a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2', 'RE', 'STANDARD', NULL, $t$Option immédiate : 15 € maintenant. Option différée : 40 € dans 14 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 2),
    ('4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3', 'RE', 'STANDARD', NULL, $t$Option immédiate : 5 € maintenant. Option différée : 12 € dans 3 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 3),
    ('c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4', 'RE', 'STANDARD', NULL, $t$Option immédiate : 50 € maintenant. Option différée : 100 € dans 30 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 4),
    ('9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5', 'RE', 'STANDARD', NULL, $t$Une offre s'affiche avec un compte à rebours visuel : « 10 € maintenant — 10 secondes restantes » (rouge clignotant) vs 15 € dans 2 jours sans contrainte de temps.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 5),
    ('48c98228-9651-52c0-b294-373733227320', 'RE-6', 'RE', 'STANDARD', NULL, $t$Option immédiate : 20 € maintenant. Option différée : 60 € dans 60 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 6),
    ('8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7', 'RE', 'STANDARD', NULL, $t$Option immédiate : 8 € maintenant. Option différée : 20 € dans 5 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 7),
    ('fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8', 'RE', 'STANDARD', NULL, $t$Option immédiate : 25 € maintenant. Option différée : 55 € dans 21 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 8),
    ('881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9', 'RE', 'STANDARD', NULL, $t$Option immédiate : 12 € maintenant. Option différée : 30 € dans 10 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 9),
    ('75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10', 'RE', 'STANDARD', NULL, $t$Option immédiate : 100 € maintenant. Option différée : 180 € dans 45 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 10),
    ('f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11', 'RE', 'STANDARD', NULL, $t$Une offre flash s'affiche : « 20 € maintenant — 15 secondes restantes » (bandeau rouge) vs 35 € dans 3 jours sans contrainte de temps.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 11),
    ('e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12', 'RE', 'STANDARD', NULL, $t$Option immédiate : 30 € maintenant. Option différée : 90 € dans 90 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 12),
    ('ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13', 'RE', 'STANDARD', NULL, $t$Option immédiate : 6 € maintenant. Option différée : 8 € dans 2 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 13),
    ('68173ddd-63fd-5019-a6db-409620345268', 'RE-14', 'RE', 'STANDARD', NULL, $t$Option immédiate : 40 € maintenant. Option différée : 70 € dans 14 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 14),
    ('02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15', 'RE', 'STANDARD', NULL, $t$Une offre s'affiche avec compte à rebours et message : « 50 € maintenant — 30 secondes » vs 80 € dans 10 jours sans contrainte de temps.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 15),
    ('b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16', 'RE', 'STANDARD', NULL, $t$Option immédiate : 18 € maintenant. Option différée : 45 € dans 30 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 16),
    ('8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17', 'RE', 'STANDARD', NULL, $t$Option immédiate : 3 € maintenant. Option différée : 8 € dans 4 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 17),
    ('b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18', 'RE', 'STANDARD', NULL, $t$Option immédiate : 200 € maintenant. Option différée : 320 € dans 60 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 18),
    ('bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19', 'RE', 'STANDARD', NULL, $t$Option immédiate : 7 € maintenant. Option différée : 18 € dans 6 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 19),
    ('fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20', 'RE', 'STANDARD', NULL, $t$Option immédiate : 22 € maintenant. Option différée : 50 € dans 20 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 20),
    ('3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21', 'RE', 'STANDARD', NULL, $t$Une offre s'affiche avec un compte à rebours : « 30 € maintenant, offre valable 20 secondes » (urgence visuelle marquée) vs 45 € dans 5 jours sans contrainte de temps.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 21),
    ('a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22', 'RE', 'STANDARD', NULL, $t$Option immédiate : 60 € maintenant. Option différée : 110 € dans 40 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 22),
    ('bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23', 'RE', 'STANDARD', NULL, $t$Option immédiate : 9 € maintenant. Option différée : 22 € dans 6 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 23),
    ('a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24', 'RE', 'STANDARD', NULL, $t$Option immédiate : 150 € maintenant. Option différée : 260 € dans 50 jours.$t$, NULL, $t$Choisissez l'option immédiate ou l'option différée.$t$, NULL, TRUE, 24);

INSERT INTO games.decision_scenario_options
    (id, scenario_id, option_id, label, quality, position)
VALUES
    ('35ab8e10-534d-5191-8b1f-56bf5095764d', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o1', $t$Je choisis B : il respecte mon plafond budgétaire et son trajet de 8 minutes reste sous les 10 minutes requises. C est hors budget et A est trop éloigné.$t$, 'OPTIMAL', 1),
    ('1b4cbf12-7687-50a4-891d-bda48cced079', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o2', $t$Je choisis B car il a de bonnes notes et un trajet acceptable.$t$, 'SATISFACTORY', 2),
    ('1c927f47-d896-5c61-9dc1-e4b835aadb2b', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o3', $t$Je choisis C car la note excellente suggère un meilleur confort pour un déplacement professionnel.$t$, 'PARTIAL', 3),
    ('d6816c16-4515-5c23-acea-1ccbed56ab67', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o4', $t$Je choisis A car j'ai l'habitude de marcher et le prix bas m'arrange.$t$, 'DEFICIENT', 4),
    ('c38df482-c5e0-5aac-b17e-059035c5a035', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o1', $t$Je choisis A : son prix reste dans mon budget et son autonomie de 2 jours couvre mes déplacements. B est insuffisant en autonomie, C dépasse mon budget.$t$, 'OPTIMAL', 1),
    ('6e1aea34-ac75-5990-8612-88bc53b1460d', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o2', $t$Je choisis A car l'autonomie me semble suffisante pour mes trajets.$t$, 'SATISFACTORY', 2),
    ('1e33e9a3-d34f-58e2-b6f0-2e3470101b24', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o3', $t$Je choisis C car une meilleure autonomie réduit le risque de panne lors d'un déplacement important.$t$, 'PARTIAL', 3),
    ('a1e1db60-676d-5b8c-9bb1-a2f8041e4f42', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o4', $t$Je choisis B car les critiques positives me rassurent sur la fiabilité.$t$, 'DEFICIENT', 4),
    ('0a0cc54f-049f-53c0-8650-f6cd1dbfe467', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o1', $t$Je choisis A : il respecte le plafond de loyer et le trajet de 25 minutes reste dans la limite. B dépasse le trajet autorisé, C dépasse le budget. Le calme du quartier est un plus mais ne peut pas primer sur les contraintes obligatoires.$t$, 'OPTIMAL', 1),
    ('6a2144aa-e9ba-57e3-ae89-60bf8c293d3f', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o2', $t$Je choisis A car le loyer et le trajet me conviennent, et le quartier calme est appréciable.$t$, 'SATISFACTORY', 2),
    ('53d2190c-7352-5df6-b8bc-fb4e73fe2637', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o3', $t$Je choisis B car le trajet de 50 min est long mais le loyer bas me permet d'économiser et le quartier calme est important pour moi.$t$, 'PARTIAL', 3),
    ('801790df-0ac3-57c2-8556-2c4cea1e7fe2', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o4', $t$Je choisis C car un trajet court est plus important que tout le reste.$t$, 'DEFICIENT', 4),
    ('f841b42c-07c7-51c7-b51b-dca6a628597d', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o1', $t$Je choisis C : c'est un CDI et le salaire atteint mon seuil minimum. A est éliminé par le salaire insuffisant, B par l'absence de stabilité contractuelle.$t$, 'OPTIMAL', 1),
    ('537c7599-20d6-5368-9b7d-eba699714476', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o2', $t$Je choisis C car c'est un CDI avec des perspectives d'évolution intéressantes.$t$, 'SATISFACTORY', 2),
    ('78b0226c-46e7-538a-876c-9051f23117d6', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o3', $t$Je choisis B : le salaire supérieur me permet d'épargner et 18 mois c'est suffisant pour me retourner.$t$, 'PARTIAL', 3),
    ('00fc30d9-d29c-5a55-a2f6-7ea571a8bde3', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o4', $t$Je choisis A car le nom du poste correspond exactement à ma formation.$t$, 'DEFICIENT', 4),
    ('bb974a08-dcc0-582b-9e39-7672310db14f', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o1', $t$Je choisis C : il respecte le budget de l'entreprise et son ambiance calme permet de conduire la réunion. A est hors budget, B trop bruyant. La différence de note entre C (4.2) et B (4.5) est non significative face aux contraintes.$t$, 'OPTIMAL', 1),
    ('8056a568-990a-53a4-9c0a-88f20a9b8dc9', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o2', $t$Je choisis C car l'ambiance calme est essentielle et le prix reste acceptable.$t$, 'SATISFACTORY', 2),
    ('d741b43c-83a9-5dd0-8394-4e4a7a1231a8', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o3', $t$Je choisis A : la note excellente et le cadre professionnel justifient un dépassement de budget ponctuel.$t$, 'PARTIAL', 3),
    ('fafc9728-55a9-5cc7-8957-c86e38d29102', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o4', $t$Je choisis B car j'y connais le chef de salle et j'obtiendrai une bonne table.$t$, 'DEFICIENT', 4),
    ('d5632baa-f9a5-5be9-8c01-d14126eb604a', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o1', $t$Je choisis C : la prime respecte mon budget et la couverture inclut mon antécédent médical. A est hors budget, B ne couvre pas mon antécédent, ce qui représente un risque financier réel.$t$, 'OPTIMAL', 1),
    ('8c27ac7a-f36b-5f4e-b6d6-d1a545019580', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o2', $t$Je choisis C car l'antécédent est couvert et le tarif est acceptable.$t$, 'SATISFACTORY', 2),
    ('b3bfe50f-4b7b-53ce-9012-aabf539c18f6', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o3', $t$Je choisis A : une couverture complète vaut l'investissement supplémentaire, surtout avec un antécédent.$t$, 'PARTIAL', 3),
    ('2b06ece1-d056-5781-a342-a33ab9409a33', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o4', $t$Je choisis B car le site internet est plus clair et facile à utiliser.$t$, 'DEFICIENT', 4),
    ('8dda646e-b83a-5eaa-9541-147406599661', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o1', $t$Je choisis A : il respecte mon budget et son autonomie de 550 km couvre largement mes trajets de 250 km. B est éliminé par une autonomie trop faible (280 km < 500 km), C par le dépassement budgétaire.$t$, 'OPTIMAL', 1),
    ('68e06f9b-54ca-592c-a31f-16889905ab05', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o2', $t$Je choisis A car l'autonomie suffit pour mes besoins professionnels.$t$, 'SATISFACTORY', 2),
    ('43d9710f-9046-58f0-a63d-b97e2c04b4d4', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o3', $t$Je choisis B : la faible consommation compensera le coût sur la durée, même si l'autonomie est limite.$t$, 'PARTIAL', 3),
    ('fff3c24a-8126-5593-a784-c3dc88c60f59', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o4', $t$Je choisis C car les commerciaux de ma connaissance préfèrent ce modèle.$t$, 'DEFICIENT', 4),
    ('8daf66ac-d9d4-59d5-b103-2a26bdf87d6a', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o1', $t$Je choisis B : le tarif est dans le budget et les horaires 7h30–19h couvrent mon amplitude 8h–18h30. A est éliminé par ses horaires trop courts, C par son tarif hors budget. Le projet bilingue de A et C est intéressant mais ne peut pas primer sur les contraintes pratiques.$t$, 'OPTIMAL', 1),
    ('d2259ccc-c932-5a6c-99e6-6261a3ff1a6e', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o2', $t$Je choisis B car les horaires et le tarif correspondent à mes besoins.$t$, 'SATISFACTORY', 2),
    ('08606590-d8cd-5f4f-8e98-645ac5d5fb08', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o3', $t$Je choisis A : le projet bilingue représente un avantage éducatif important pour le développement de mon enfant.$t$, 'PARTIAL', 3),
    ('dd3498a9-8b99-5ed0-b363-dd2bcbba5f82', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o4', $t$Je choisis C car la décoration des locaux est plus moderne et rassurante.$t$, 'DEFICIENT', 4),
    ('6c9fa250-6897-5ee6-8bc3-c340c9cece71', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o1', $t$Je choisis C : l'abonnement respecte mon budget et la salle est à 12 minutes, soit sous les 15 minutes requises. A est trop loin (40 min), B dépasse le budget.$t$, 'OPTIMAL', 1),
    ('89ad09d3-64cc-5a89-b8e2-ebeecb9ad896', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o2', $t$Je choisis C car la distance et le tarif me conviennent malgré des équipements légèrement moins récents.$t$, 'SATISFACTORY', 2),
    ('a03e6e0f-906d-5bfc-b739-5775738e5807', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o3', $t$Je choisis A : les équipements récents valent le trajet plus long, surtout si j'y vais en vélo.$t$, 'PARTIAL', 3),
    ('4c9813c3-01fe-5d36-a41e-6bc059ebcb26', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o4', $t$Je choisis B car l'ambiance de la salle m'a semblé meilleure lors de ma visite.$t$, 'DEFICIENT', 4),
    ('6fdb5d10-462e-5785-82f8-fadb260640fb', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o1', $t$Je choisis C : la licence respecte le budget et l'intégration couvre la messagerie et le CRM, ce qui est la condition posée. A est incompatible, B n'assure qu'une compatibilité partielle.$t$, 'OPTIMAL', 1),
    ('231cfd22-6099-55dc-b415-e1d9aecb63ad', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o2', $t$Je choisis C car il est pleinement compatible avec notre environnement actuel.$t$, 'SATISFACTORY', 2),
    ('c3e56a01-eba7-5122-ac23-b64e654350c2', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o3', $t$Je choisis B : la compatibilité messagerie couvre l'essentiel du travail collaboratif, le CRM peut être connecté manuellement.$t$, 'PARTIAL', 3),
    ('1f9283e7-ba48-5dff-b5e6-8a27929a3021', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o4', $t$Je choisis A car l'interface graphique est plus intuitive selon les démos en ligne.$t$, 'DEFICIENT', 4),
    ('3983c9ee-e927-53a5-988a-51044e6feb51', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o1', $t$Je choisis C : le tarif est dans le budget et le délai de 6 jours respecte l'exigence contractuelle de 7 jours. A dépasse le délai (18 j), B dépasse le budget. L'absence de certification ISO de C est un point de vigilance à surveiller lors du renouvellement.$t$, 'OPTIMAL', 1),
    ('5f512df0-ffee-5327-80af-aee4e089151f', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o2', $t$Je choisis C car le délai et le prix correspondent aux exigences du contrat.$t$, 'SATISFACTORY', 2),
    ('fcae1fb9-5f5c-5473-9b5a-b7dc2a997fc6', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o3', $t$Je choisis A : la certification ISO 9001 garantit une qualité plus fiable sur la durée, même si le délai est plus long.$t$, 'PARTIAL', 3),
    ('5ffecfc2-4610-5289-ae51-8f23fd62f6b3', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o4', $t$Je choisis B car un fournisseur cher inspire plus confiance pour un contrat stratégique.$t$, 'DEFICIENT', 4),
    ('1923e7be-27d6-5bec-b5d2-050c67ff56a5', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o1', $t$Je choisis B : le tarif respecte mon budget et le format soirée est compatible avec mon emploi du temps. A est éliminé par son format journée incompatible. C est hors budget. La reconnaissance internationale de C est attrayante mais sans rapport avec mon usage prévu.$t$, 'OPTIMAL', 1),
    ('bd6ed22c-709e-5992-9aef-68663bb9ad12', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o2', $t$Je choisis B car les horaires et le budget me conviennent.$t$, 'SATISFACTORY', 2),
    ('ba74622a-d004-5e6d-be7e-42e9715ac969', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o3', $t$Je choisis C : la reconnaissance internationale est un investissement dans ma carrière à long terme.$t$, 'PARTIAL', 3),
    ('9e22253c-fbdf-5b70-a232-8734139ab802', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o4', $t$Je choisis A car le nom de l'organisme de formation m'est familier.$t$, 'DEFICIENT', 4),
    ('51e6f000-e5db-5cc1-93d1-ce17a172a79a', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o1', $t$Je choisis A : le tarif respecte le budget et l'assurance couvre intégralement la valeur de mes biens. B sous-assure (50%), ce qui représente un risque financier direct. C est hors budget.$t$, 'OPTIMAL', 1),
    ('e6f8588b-7021-5ce6-b13e-708796cca742', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o2', $t$Je choisis A car l'assurance est complète et le prix est acceptable.$t$, 'SATISFACTORY', 2),
    ('d256500b-65d3-5e75-942e-b344c2a13f4f', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o3', $t$Je choisis B : disponible immédiatement et le surcoût d'assurance peut être souscrit séparément auprès de mon assureur.$t$, 'PARTIAL', 3),
    ('5c10b247-98e1-526f-950a-00d2c30d77b8', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o4', $t$Je choisis C car les camions neufs indiquent une entreprise sérieuse.$t$, 'DEFICIENT', 4),
    ('f9b9ad30-d3b6-5886-b423-057f73ff6f3a', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o1', $t$Je choisis B : le tarif est dans le budget et les 100 Mb/s couvrent largement les besoins en visioconférence et transferts. A est éliminé par un débit insuffisant (20 Mb/s < 50 Mb/s requis), C par le dépassement budgétaire.$t$, 'OPTIMAL', 1),
    ('418b0e1a-b7eb-5842-9886-5af150561382', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o2', $t$Je choisis B car le débit est suffisant pour mes usages professionnels.$t$, 'SATISFACTORY', 2),
    ('ed5e2f52-f2ab-5515-953b-85fe73ae88ec', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o3', $t$Je choisis C : la fibre optique 500 Mb/s garantit une stabilité supérieure lors des pics d'utilisation.$t$, 'PARTIAL', 3),
    ('71abe258-c7d7-57ca-843f-283e28dca9eb', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o4', $t$Je choisis A car cet opérateur est celui que j'ai toujours utilisé.$t$, 'DEFICIENT', 4),
    ('603bf571-7b73-569c-baf8-8b76840fdc94', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o1', $t$Je choisis C : le tarif est dans le budget et les 4h de salle incluses par semaine couvrent nos besoins habituels. A ne propose aucune salle privée, B dépasse le budget.$t$, 'OPTIMAL', 1),
    ('a8ed3ff5-b99e-502c-a634-15069d2f31d9', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o2', $t$Je choisis C car les salles de réunion sont disponibles et le tarif est acceptable.$t$, 'SATISFACTORY', 2),
    ('c9fba659-3d94-50c3-acbd-5f62330972e7', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o3', $t$Je choisis B : l'accès 24h/24 offre une flexibilité utile pour une équipe aux horaires variables.$t$, 'PARTIAL', 3),
    ('6119ce91-2453-5796-bec2-9a70e170970f', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o4', $t$Je choisis A car la décoration est plus moderne et l'ambiance propice à la créativité.$t$, 'DEFICIENT', 4),
    ('50139aef-37b5-5acd-b25d-54a98e65406a', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o1', $t$Je choisis B : le tarif respecte le budget et les menus couvrent les deux régimes identifiés (sans gluten et végétarien). A ne propose aucune adaptation, C dépasse le budget.$t$, 'OPTIMAL', 1),
    ('3c3abbd8-53a7-59d4-9c79-8a685bb490cd', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o2', $t$Je choisis B car les menus sont adaptés aux contraintes alimentaires de nos invités.$t$, 'SATISFACTORY', 2),
    ('684e4c18-1d4e-5b5b-baeb-3aa35f96fe09', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o3', $t$Je choisis A : les invités avec allergies peuvent apporter leur propre repas, ce qui est courant dans ce type d'événement.$t$, 'PARTIAL', 3),
    ('0b65377b-1c24-516b-8cb7-b7f29f441cfc', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o4', $t$Je choisis C car un traiteur gastronomique valorise l'image de l'entreprise.$t$, 'DEFICIENT', 4),
    ('edb3441c-fc4f-55c9-af1c-ab79644db95a', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o1', $t$Je choisis A : le tarif est dans le budget et la salle peut accueillir 150 personnes, soit 10 de plus que les 140 prévus. B est éliminé par une capacité insuffisante (90 < 140), C par le dépassement budgétaire.$t$, 'OPTIMAL', 1),
    ('9c5687d9-a2e3-5a59-85da-526e1895f974', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o2', $t$Je choisis A car la capacité est suffisante et le budget est respecté.$t$, 'SATISFACTORY', 2),
    ('efdd9d4f-eee0-5cb1-b948-f496278a001a', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o3', $t$Je choisis C : une salle plus grande offre une marge de sécurité utile si des invités de dernière minute se présentent.$t$, 'PARTIAL', 3),
    ('8a7faf14-d0cf-53fa-a2b5-2483308face9', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o4', $t$Je choisis B car la proximité des transports en commun est importante pour l'accessibilité.$t$, 'DEFICIENT', 4),
    ('4971e0b8-44b1-52ac-a42a-caefce214285', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o1', $t$Je choisis B : le tarif est dans le budget et les spécifications (16 Go RAM, GPU 4 Go) sont suffisantes pour les logiciels de retouche et montage utilisés. A est éliminé par des performances insuffisantes pour le montage 4K, C par le dépassement budgétaire.$t$, 'OPTIMAL', 1),
    ('3feeb88d-49d4-58a1-8af2-609ee141eb5d', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o2', $t$Je choisis B car les performances couvrent les besoins professionnels du graphiste.$t$, 'SATISFACTORY', 2),
    ('a75eae0d-9aac-5810-9b2e-5ddcc2c5c315', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o3', $t$Je choisis C : investir dans la meilleure configuration réduit les risques de lenteur et prolonge la durée de vie utile de la machine.$t$, 'PARTIAL', 3),
    ('d9b36ac0-f0d4-57a0-9c2e-a3b4ee4a2e48', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o4', $t$Je choisis A car le design est plus léger, ce qui est pratique pour les déplacements.$t$, 'DEFICIENT', 4),
    ('6eb85c4d-2900-54a0-a8b3-e13ac37162bc', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o1', $t$Je choisis A : le loyer respecte mon budget et l'accès PMR conforme répond à mon obligation réglementaire, contrairement à B (non accessible) et C (hors budget).$t$, 'OPTIMAL', 1),
    ('b019c34b-daa0-574a-b5d4-17000616430a', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o2', $t$Je choisis A car l'accessibilité me semble correcte.$t$, 'SATISFACTORY', 2),
    ('763bd3d3-418a-5c64-a107-d04abef2522c', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o3', $t$Je choisis C car un local plus cher est toujours mieux situé.$t$, 'PARTIAL', 3),
    ('3428532d-0c20-5419-a088-06d7276df872', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o4', $t$Je choisis B car la façade est plus esthétique.$t$, 'DEFICIENT', 4),
    ('0b84d280-1aa2-562b-bb3c-251b6fb43c3a', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o1', $t$Je choisis A : le tarif respecte mon budget et le véhicule est compatible avec mon permis B, contrairement à B (permis non détenu) et C (hors budget).$t$, 'OPTIMAL', 1),
    ('1894dae4-b255-53c9-9c9a-aa537b85d2de', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o2', $t$Je choisis A car le véhicule me semble facile à conduire.$t$, 'SATISFACTORY', 2),
    ('722c38e6-b518-5872-a3cd-f9928a57c545', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o3', $t$Je choisis C car un camion plus cher est toujours plus fiable.$t$, 'PARTIAL', 3),
    ('e08c8ddd-7cd2-527c-a2c5-5c057ce272c7', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o4', $t$Je choisis B car la couleur du camion est plus discrète.$t$, 'DEFICIENT', 4),
    ('3bd3e82b-ba65-503d-a3df-110e14d45dab', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o1', $t$Je choisis C : le tarif respecte mon budget et un vétérinaire est sur place pour le traitement de mon chien, contrairement à A (pas de vétérinaire) et B (hors budget).$t$, 'OPTIMAL', 1),
    ('877133d2-f033-56ad-a772-8a26dcd72721', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o2', $t$Je choisis C car un vétérinaire est présent.$t$, 'SATISFACTORY', 2),
    ('a3be7c88-6329-5e7b-a7ae-034a5fde2f5d', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o3', $t$Je choisis B car une pension plus chère est toujours plus sérieuse.$t$, 'PARTIAL', 3),
    ('2905f646-80a2-5935-a181-dfc52c0dd617', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o4', $t$Je choisis A car les locaux ont l'air spacieux sur les photos.$t$, 'DEFICIENT', 4),
    ('c91cf9d8-f336-5cb1-8a13-91a16e562cc0', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o1', $t$Je choisis A : le tarif respecte mon budget et l'électricité est certifiée renouvelable, comme l'exige ma charte RSE, contrairement à B (hors budget) et C (non certifiée).$t$, 'OPTIMAL', 1),
    ('024a4b0f-c5cc-5db1-9ba5-be77f1b97fb3', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o2', $t$Je choisis A car l'électricité me semble verte.$t$, 'SATISFACTORY', 2),
    ('a22c04f0-71f5-5071-a9bd-b4a49e962cbe', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o3', $t$Je choisis B car un fournisseur plus cher est toujours plus fiable.$t$, 'PARTIAL', 3),
    ('494d9c0d-78ed-576e-94be-08d904dafdad', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o4', $t$Je choisis C car le site du fournisseur est plus moderne.$t$, 'DEFICIENT', 4),
    ('e897530f-bde9-5bdb-a7d2-d76ea03b0b91', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o1', $t$Je choisis A : les honoraires respectent mon budget et la spécialisation en droit commercial correspond à mon dossier, contrairement à B (non spécialisé) et C (hors budget).$t$, 'OPTIMAL', 1),
    ('f662e090-fcfc-59d3-9148-5bd991a29466', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o2', $t$Je choisis A car l'avocat me semble compétent.$t$, 'SATISFACTORY', 2),
    ('6e8963c0-7de4-57ff-ae60-2afab5c1d068', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o3', $t$Je choisis C car un avocat plus cher gagne toujours plus de dossiers.$t$, 'PARTIAL', 3),
    ('b0b53e4a-c407-55cd-b2a7-36f47bfbd561', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o4', $t$Je choisis B car le cabinet est plus proche de mon domicile.$t$, 'DEFICIENT', 4),
    ('9b5d8d55-6d73-5be8-8deb-2cfeb5e64b84', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o1', $t$Je choisis A : le tarif respecte mon budget et l'équipe est habilitée travail en hauteur, comme l'exige la réglementation, contrairement à B (non habilitée) et C (hors budget).$t$, 'OPTIMAL', 1),
    ('8f804d44-c4fb-5277-bcd7-cb379ed5b694', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o2', $t$Je choisis A car l'équipe me semble compétente.$t$, 'SATISFACTORY', 2),
    ('e2d933a0-2ae8-5772-9d78-9e37f2a23ca7', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o3', $t$Je choisis C car un prestataire plus cher est toujours plus sérieux.$t$, 'PARTIAL', 3),
    ('0bc0ea9a-6273-50c2-a7c5-4b928860da29', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o4', $t$Je choisis B car les avis en ligne sont nombreux.$t$, 'DEFICIENT', 4),
    ('f3836d38-5350-5bd9-99bc-798ff991fe7c', 'ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('0a0262fb-2b3d-5c62-ac7b-c0b8484f0ee6', 'ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('a3ca85ea-7683-5813-a89d-c48bbb13fdba', '3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('67fbed93-f333-59f6-b1e6-f31e50b92e3a', '3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('f11fa9e4-7bfe-5dd6-a322-8568ba8c243e', 'ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('33ab888b-885d-5fc9-8e8f-2fa6052d8500', 'ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('8d9b9a78-409b-5047-9866-a53792610f78', '524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('26832cf9-d59f-596e-b6db-13c919cbef5e', '524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('edecd206-60bc-5a5e-86bd-91cdc27d4c16', '554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('2edf257e-dffc-5191-b6a1-bd33c09930f0', '554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('78256fac-a63c-5739-b7f7-a2eaf98959fb', 'e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('4eab7035-99a4-5e26-a3eb-117fb8315fa4', 'e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('b644ce0e-25aa-59e4-b73d-97e7028c2d42', '7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('3de78682-725a-5058-ac1b-0fed16e5f219', '7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('88817352-6f44-55de-a7e1-a14533e52ee1', 'bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('f9fdaeb2-20d3-584e-bb90-baf598a93596', 'bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('e6bd5d2f-2d32-5b78-8b70-88d85800c121', '8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('fa02e736-a1ec-5792-bd11-34203a0d70f9', '8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('372ac519-4e77-580a-977c-6fb04c1b10e4', 'b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('b87dbe1a-8f18-505a-8cfe-5eea63e98782', 'b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('1adecb50-0d38-5fc0-9024-d2425d4c9878', 'e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('462c1eb4-96ec-5b5c-aad5-e5dcfd0018f9', 'e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('e422509f-4c9f-5293-a339-64a6971cd083', '19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('fddc741e-1c51-5e46-8050-fae4b36a05be', '19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('8c0c7b42-dea9-5f6e-8696-98af4a95906d', '7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('0eaae52b-829d-55db-a239-81b3cdb364d4', '7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('1c049bfc-1e11-5304-8590-03fb463e0c12', 'e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('76747195-0a06-5945-9dea-b1f59957e1ae', 'e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('0c000d3a-d6bf-5180-9e31-53b28ebfa890', '037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('75d2078b-7d7d-5e76-b28e-f90cbc1b701e', '037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('08bcd0f0-79d6-5d45-b013-259e82ba960b', '6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('d41e7e61-c43e-52c5-8c9e-abf835b9e9db', '6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('39ae53dc-dd22-5573-888d-6a7d5923e906', '6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('1182a920-9fb3-5454-8cd6-402e2d29c728', '6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('3eb39254-e146-5e28-8094-ca78d62bf14a', '61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18-X', $t$Option X$t$, 'SATISFACTORY', 1),
    ('cc1f0fdc-3266-5dc1-bf5f-e41b957b839a', '61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18-Y', $t$Option Y$t$, 'SATISFACTORY', 2),
    ('e1552bc1-d6a6-5c8c-9cac-6682c855fcaa', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o1', $t$Choix de Y — maximise l'utilité espérée (75 € > 60 €).$t$, 'OPTIMAL', 1),
    ('d264a7b3-42e4-5508-b209-273b9962d642', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o2', $t$Choix de X avec justification partielle cohérente (ex. aversion au risque explicitement déclarée).$t$, 'SATISFACTORY', 2),
    ('0efff163-0077-534b-bd36-67d45bca5fa6', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o3', $t$Choix de X sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('99a64320-8dcb-52d9-8d2e-92095507575c', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('df069d76-ac01-548f-97a1-e970abbed0a2', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o1', $t$Choix de X — minimise la perte espérée (−40 € > −50 €).$t$, 'OPTIMAL', 1),
    ('1191f1d0-a0d8-5fb5-a2ae-f7a93a81d395', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o2', $t$Choix de Y avec justification partielle cohérente.$t$, 'SATISFACTORY', 2),
    ('16873c44-9d0e-5301-8e33-e9ccdf2fc872', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o3', $t$Choix de Y sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('48d6f8b2-9a09-5112-9dbd-25abd1ad6bc1', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('2db30a44-380b-54ae-b8ab-8997c09e573a', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o1', $t$Choix de Y — maximise l'utilité espérée (140 € > 120 €).$t$, 'OPTIMAL', 1),
    ('e7270ba3-c6ff-5467-a252-b905fe228405', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o2', $t$Choix de X avec justification partielle cohérente.$t$, 'SATISFACTORY', 2),
    ('53d6b7a9-cc8f-5e62-8d58-9baedfab51f3', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o3', $t$Choix de X sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('48f6a541-24ab-5608-9d0f-4e86e5ef023d', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('6924357b-aa26-54a1-a698-bad20e4d7095', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o1', $t$Choix de X — minimise la perte espérée (−60 € > −70 €).$t$, 'OPTIMAL', 1),
    ('f635d80f-4a7e-5074-8fba-e804b50f8dd5', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o2', $t$Choix de Y avec justification partielle cohérente.$t$, 'SATISFACTORY', 2),
    ('33379b5b-b4e4-5931-904e-3eae17218125', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o3', $t$Choix de Y sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('8d91f023-d81d-5a2b-926f-b1c3227ed80d', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('61b3bc8e-2c1b-5d62-8d31-245427b2960e', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o1', $t$Choix de Y — maximise l'utilité espérée (50 € > 45 €).$t$, 'OPTIMAL', 1),
    ('bef901f3-52ae-5c92-b066-8981127682d4', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o2', $t$Choix de X avec justification partielle cohérente.$t$, 'SATISFACTORY', 2),
    ('caaa3147-7f4f-58e8-bc9a-f60aeeb64d28', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o3', $t$Choix de X sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('6e86d14b-c425-57af-ad5b-1862588a29b0', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('ade07f99-e388-5146-92b1-0a9c7cfbd55a', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o1', $t$Choix de X — minimise la perte espérée (−250 € > −280 €).$t$, 'OPTIMAL', 1),
    ('b87df35a-a073-54f4-92dc-12db4725a1a6', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o2', $t$Choix de Y avec justification partielle cohérente.$t$, 'SATISFACTORY', 2),
    ('c3b14eb9-4364-52c5-96a2-fcc4e3bb2015', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o3', $t$Choix de Y sans justification ou avec justification incohérente.$t$, 'PARTIAL', 3),
    ('97c74975-9f75-5930-a7cc-57157d067b96', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o4', $t$Réponse incohérente ou absente.$t$, 'DEFICIENT', 4),
    ('f5630837-f3a0-5788-8a88-c43c9a049c6a', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('ed8dfc2d-8a11-540f-bf40-9c262ef9c1b2', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('7ed4c7fd-827e-5f9e-852d-d2a2f9519def', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('31cd67ba-ae8b-5e0a-b20b-a74e95890955', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('aae89639-4b7f-5383-969b-a362294a47bf', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('8751130b-bb14-5948-967d-cef2a4076317', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('93a71db4-8627-517b-bba1-46d69edc1a63', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('cfd61e25-3767-5c02-b7ed-b1a90eedf3d1', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('a473f9a9-81b3-5fcb-9a99-1d6c7fdcc78b', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('a8b61728-39a7-58cf-931e-d4b2bbafcacc', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('18cb2179-8340-5610-91b9-c31258e7206d', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('55b6d53a-789a-5230-83bb-d4a881ba44a6', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('3d43391a-7783-53e2-823f-fb6a726ac085', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('82e6d8a1-3245-5128-aa7a-0e05f9f6709d', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('0a033855-7831-505d-bae7-b5dfc85af7de', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('fc9d4d71-d1a5-5b62-8056-1cf774d9ee67', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('3e6fe870-4936-50fc-a352-f9b889a562bd', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('b1ca8f7c-61bc-50a3-90a4-33856bece3b2', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('4afa7948-4932-5514-9c8b-7dae2890d65c', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('df440d38-9f99-5e87-89ab-c530a7bdc325', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('29650e78-205a-5530-b2b6-298cb72574b7', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('53d363a6-12c7-57a3-a00d-61eb045d66cc', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('1ef9eea3-ab12-5434-b610-7527dee660ee', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('ce46b51e-2bd8-5dcd-a66d-a7612cfcf7ef', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('71743d18-3021-58b0-8fcb-362c744dae43', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('1b9db7ff-eaec-5afb-a593-2e4fd6cd28a6', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('41db11e0-8ee9-5e9c-a863-5c0fcc129edf', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('ac56da70-6ea9-59cf-9858-f07aa8af5c6a', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('edb50f43-e6e0-5194-a733-1a5e9d3b0a73', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('5676ed1d-ec54-5b87-8de3-43aa98597032', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('1761d9fd-c353-5fc6-9343-6782b1240429', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('654fd005-ff61-571f-ba8a-8068777043ab', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('12af20ac-ddc5-5233-ba2e-bb862836a120', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('cf3a61a6-83d0-5520-8a2f-7607ad0d1269', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('710ddbe6-6aac-5c8d-9c00-00680fe384c1', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('660dbefc-5d38-5b5a-aaea-2d552cdfaadc', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('083346ba-ff8f-5f2f-9697-6fc2ea6a8120', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('367ecf99-a552-552f-89af-d7a461f08538', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('59ffcf8b-c390-560b-85f6-233655430167', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('03af5a3e-c0fa-586b-babe-6824a83ba257', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('9b558939-a41f-5778-9e85-8f4ed2e02060', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('e90e3a5d-b4b2-59e7-ade1-c7caad6388c6', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('c0a4181b-86a1-5a26-a1ee-5e02298c4609', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('624b3a31-1860-5cca-9063-c2c54f6cf6ab', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('b9c591a5-5d4c-5451-b717-c0d30d767f1f', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('94f937e5-7909-5680-85a3-c810be940bb1', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('5cb1afb9-04d1-55f8-aad8-20a81f5a9e83', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('44ed6059-aea7-54c5-8ed2-4c5bc12adbe7', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('91c9cf84-2d01-5cb9-aba9-e7b432eb2397', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('d390fa52-067e-5363-95bc-9357e2c98b83', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('c812ba98-c273-5d22-a931-bd067c3ae44a', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('39066a0c-59f7-524b-abb5-bbfd5b5bfd54', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('e923b30b-ba69-53d7-b80d-96fafd2e466f', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('ed6fa99f-fea2-5dab-abc0-6d26740a9326', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('cad19753-2e70-5248-8235-c7a0e24c41a5', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('e285fbe7-b66b-5258-936f-9fadb8723653', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('f9a9a14c-b175-5c73-bbbc-c7b10d8d4a2d', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('4c3dcb53-421c-5c62-9b5e-2c65f0e97acc', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('541ce987-a317-551a-a09c-8176fb33dcc8', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('a4c31a04-a97c-5a22-b87c-8f1b544fa1f9', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('9367a23c-d956-5c26-bee4-a474c5c6111d', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('7d35b6b5-9c88-5613-a16f-10ced83d892e', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('d6ed004e-eb96-5a01-878e-8f7fd8ab9de9', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('7fe44315-2d5a-5f85-9a1a-b1249a62558e', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('aa65d1bd-253e-547d-bf85-0c110e9f4039', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-B', $t$Option B$t$, 'OPTIMAL', 2),
    ('39105868-cfc7-52a7-82da-1ae27f2c59be', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('00a12257-5311-52d9-b463-3e18cc26d29b', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-A', $t$Option A$t$, 'OPTIMAL', 1),
    ('e5c582a8-46ad-5e85-ae5c-b1d0664fe956', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('c468c687-d176-540a-b422-74b634ad7c00', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-C', $t$Option C$t$, 'DEFICIENT', 3),
    ('6e2d8967-9254-50f2-ba92-9cbb26ff4f53', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-A', $t$Option A$t$, 'DEFICIENT', 1),
    ('10bccf4f-d85a-53af-91cb-1fbb05d9d6ed', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-B', $t$Option B$t$, 'DEFICIENT', 2),
    ('b43390cd-6249-553b-bd16-b4d2da532cfd', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-C', $t$Option C$t$, 'OPTIMAL', 3),
    ('6c078040-9aff-599f-b003-10f41ad6f6e6', '11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('ca9026b1-e8f3-56d5-9b21-647bc4998a40', '11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('36b4d4e1-19e5-587a-bfb7-35e5e389222f', '2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('9cc0da5d-555e-54e0-854d-7bdff7c58ec2', '2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('4244df0c-e4b7-59b2-ab33-0c4a68e6c603', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('d320c993-a67c-523d-ac22-21886aae08d0', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('6ce422d3-6ca9-5b9b-8165-2b10faf53dc0', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('adce558d-7e93-56c7-b005-bc51dd29e997', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('9ea47f1a-4873-5e40-b469-fa04e549d1d3', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('0a4a97bf-5638-5483-8d40-e2394955e886', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('8ebea235-e2df-5e90-afdd-debf1b900c3a', '91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('37f85506-7924-57a0-b429-c8c53e32dcdb', '91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('b04d2fd2-7103-5d5e-9032-ba2de9619fac', '38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('fd7f75e1-7518-5ed0-93dc-4fa770559a23', '38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('5fcdcde9-2d48-59fe-8de4-e9f5b96f275d', '308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('dac02a1a-74e6-5fcc-9b65-4e1d4105e618', '308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('3e0db0bb-42d4-5a36-a698-a7a98aca72a4', '9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('bb19118d-b7c5-576f-ab16-e34d32b337e3', '9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('802c09ec-bd66-5b79-ac06-3bb6d5f38c38', 'b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('88d1ac4b-eb19-5fc0-b5d1-b41ad9569628', 'b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('c6e1582c-8c9f-524e-bb99-ee81fb45a076', 'bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('d9a80853-8247-5a0d-8edd-c78cb1970d8d', 'bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('88080917-a8e0-5be1-a4fa-fac070cfce99', '7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('1c2135a8-8065-5266-8121-caaaebf9633b', '7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('2e355635-277a-5522-bf87-bf1036e63ec2', '4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('c4f84528-739f-5218-a900-9033f3130e26', '4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('8b6df7db-cd3e-5be0-96f0-825181a12ab8', 'e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('2751ac1e-76b9-563d-ab98-c83a10bce056', 'e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('2c0db527-b5f9-5889-967b-3957870f6b56', '1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('3da0adfa-c4ab-5684-a795-bc9381fa0309', '1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('b459d7fe-c19f-5a86-9461-f7978c418e15', '8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('7e1872c8-ae6d-58af-903d-1829d00da945', '8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('99c1d13c-1f6b-5bdd-a949-f5b9697e1711', '364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('d209f792-363a-5651-850f-fac05211094b', '364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('b3c17631-96fc-531a-8c11-f749b41681c0', 'da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('5c87ad07-91fa-5876-bec6-58b8f2ef0e41', 'da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('cde6c180-5bbf-5b5a-bca1-f433c894ca9b', '5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('53d92898-ae83-5289-99d6-975b45032258', '5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('6c87c23a-730e-5390-96db-b4b6f451b3a7', '07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('4a6ff0fd-9473-5698-818d-7d0266ca1837', '07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('263b1f22-d437-5080-834c-5a76d446f9a5', 'e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('518de00e-c847-5fe4-8983-07dce930c00f', 'e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('69207ac6-a7b4-51c9-b63c-52f7b7dcc88c', '1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('20a2cc01-f908-505f-ad45-c76f5be491bb', '1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('2d70e3b2-eb12-5875-8ca5-1be5cab57384', '554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('0d9201b2-d165-5831-94a6-770dfa1ce55b', '554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('4b92fa91-b7b1-54c8-832f-4dd477cffabb', '908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b-A', $t$Plan / Option A$t$, 'SATISFACTORY', 1),
    ('33a961c2-66f5-59e5-a6d6-127366ad86d5', '908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b-B', $t$Plan / Option B$t$, 'SATISFACTORY', 2),
    ('5b14bb6b-75ab-5595-96d5-c139933281b8', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('be39b96e-bce4-5fe5-b275-a634db1a8d0f', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('bda60765-44e2-520a-9b9a-7562a9532532', 'a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('6a743dca-19b2-5b68-904e-236a7fddf810', 'a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('c00e1a6b-a4e4-51e5-9e8e-3595a6e2cfdb', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('5d9e65b0-19df-5e91-9f7a-aeeb72dd90ec', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('bd8cb0af-1513-55be-9b39-dfb085b8720a', 'c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('3bd3286d-79c2-5cb4-9977-365f65bc205b', 'c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('4e4fa165-f5da-5665-9418-95c0abae0c30', '9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('7084ac9a-1f1a-52d7-b3ef-be4610020046', '9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('f407578c-bc42-5e0a-a141-03f9dd12fd75', '48c98228-9651-52c0-b294-373733227320', 'RE-6-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('0aa710a6-7401-58bc-be38-9bf540fade30', '48c98228-9651-52c0-b294-373733227320', 'RE-6-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('859aee84-b482-57f6-8b71-9bc82c3ecf9a', '8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('bb6cd4ec-9899-571e-a55c-e45497af3067', '8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('1bd4f824-5a28-5d9f-b3df-934b637a55aa', 'fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('0a5f1d17-2926-50bf-9ac4-7f44007914e1', 'fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('fd69efb8-ce71-508f-883c-79588db334d6', '881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('f781da2e-a290-55b8-99bd-2a396b8e7629', '881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('c60d5b38-9c8c-558f-848b-6275b2547118', '75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('47240920-2d56-5eff-8b67-ec1a7b950d8b', '75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('08826d10-a690-524c-b849-a71d9419e8e2', 'f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('51a91f9a-ad1f-5b8c-99c7-2897d3e295f8', 'f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('d967ec9e-772d-5618-bb4a-ed25d13a5ef4', 'e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('f958a36f-e695-540a-8b7c-f55dcfabc53e', 'e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('e7f0ed50-f91f-50bd-a1c4-f698e8f4fcea', 'ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('6e49792c-2bb8-561b-a9ac-b9c59c1678b4', 'ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('e22c739d-7f7c-5a16-9888-19128a459078', '68173ddd-63fd-5019-a6db-409620345268', 'RE-14-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('54d34544-e6b6-5577-9b06-6c619d5b30ac', '68173ddd-63fd-5019-a6db-409620345268', 'RE-14-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('b040c309-206f-558f-90fd-abd8f8b4a662', '02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('9dae2b7c-464c-54e9-9a12-a772fedb7ca8', '02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('61894c1e-a34b-5220-a563-45e6f1b801ac', 'b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('b5b62fdf-5555-50d2-a42e-4a1b3d2df97f', 'b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('879b88ca-9b4c-5f06-a466-aba9770563a6', '8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('5f51bfaa-0b0d-5b7b-a8f3-22d474c8ff41', '8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('31291669-0bd8-5dcc-8eb4-6e5834d27c44', 'b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('4841ab08-96c0-523d-9361-920074c99989', 'b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('f01adda8-912c-5fc5-b3f1-246047a5e084', 'bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('d4e866cd-59b2-548b-8213-716aec133042', 'bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('e44b24f6-1e43-576e-8642-12963ffa5474', 'fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('f8b7583b-2ced-5b24-a526-5a1bffcb311b', 'fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('4289298e-c1c2-5971-8f78-008f866f3cc4', '3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('9ed5117a-55db-501e-af98-e6be77e48571', '3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('06544920-5733-5fdb-bd42-e7faefda2193', 'a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('4173d1fe-2fdb-5a73-8437-a92209d77179', 'a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('07ae1a5a-ae0d-50cb-9ea5-717c013203c9', 'bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('a410f0ce-5886-5754-9def-2c61c0512ed5', 'bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2),
    ('816ff20d-a39b-554f-bb3a-2efe32f1027d', 'a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24-IMMEDIATE', $t$Option immédiate$t$, 'SATISFACTORY', 1),
    ('f459ad30-b378-5da4-849b-00d7be7dddd0', 'a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24-DEFERRED', $t$Option différée$t$, 'SATISFACTORY', 2);

-- Forme A — 6 items par dimension (voir en-tête pour le choix de composition).
INSERT INTO games.decision_form_items (form_code, scenario_id, position)
VALUES
    ('A', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 1),
    ('A', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 2),
    ('A', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 3),
    ('A', '87e601d9-7eb5-543a-a918-190e56ad20ca', 4),
    ('A', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 5),
    ('A', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 6),
    ('A', '557c9f6b-5914-5beb-bffe-60715024d51a', 7),
    ('A', '44e694aa-8313-5dd1-9015-8e81561ad03f', 8),
    ('A', '58a504a1-4260-5f88-8ded-3f03907dc852', 9),
    ('A', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 10),
    ('A', '67432a01-21e8-594e-b5cc-5e34e156e24d', 11),
    ('A', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 12),
    ('A', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 13),
    ('A', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 14),
    ('A', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 15),
    ('A', '63650717-5648-5191-91c5-244cbaa017f6', 16),
    ('A', '71b34741-0338-5fb6-aade-816894f23a66', 17),
    ('A', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 18),
    ('A', '11c5c597-5e93-5a1b-aa14-805d47871e81', 19),
    ('A', '2a108c71-8ae8-5409-a136-c57fd38752cb', 20),
    ('A', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 21),
    ('A', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 22),
    ('A', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 23),
    ('A', '91301756-fed8-535f-807f-d36e41a520f7', 24),
    ('A', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 25),
    ('A', 'a139e36e-407a-54af-a904-a0311a1c2318', 26),
    ('A', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 27),
    ('A', 'c5165793-f872-5631-a530-2aa0ce91adab', 28),
    ('A', '9005bc10-455e-5de5-87d9-5684042440e2', 29),
    ('A', '48c98228-9651-52c0-b294-373733227320', 30);

-- ── 6. Contrôles d'intégrité du seed ────────────────────────────────────────
-- Échouent la migration plutôt que de laisser passer un catalogue tronqué.

DO $$
DECLARE n INT;
BEGIN
    SELECT count(*) INTO n FROM games.decision_scenarios;
    IF n <> 120 THEN
        RAISE EXCEPTION 'Banque « Je Décide » : % items au lieu de 120', n;
    END IF;

    SELECT count(*) INTO n FROM (
        SELECT dimension FROM games.decision_scenarios
        GROUP BY dimension HAVING count(*) <> 24) d;
    IF n <> 0 THEN
        RAISE EXCEPTION '% dimension(s) n''ont pas 24 items', n;
    END IF;

    SELECT count(*) INTO n FROM games.decision_scenarios
     WHERE provisional_scoring;
    IF n <> 66 THEN
        RAISE EXCEPTION '% items provisoires au lieu de 66', n;
    END IF;

    -- Aucun scénario orphelin d'options, et au moins deux options par item.
    SELECT count(*) INTO n FROM games.decision_scenarios s
     WHERE (SELECT count(*) FROM games.decision_scenario_options o
             WHERE o.scenario_id = s.id) < 2;
    IF n <> 0 THEN
        RAISE EXCEPTION '% item(s) avec moins de 2 options', n;
    END IF;

    -- Exactement une option OPTIMAL par item réellement noté.
    SELECT count(*) INTO n FROM games.decision_scenarios s
     WHERE NOT s.provisional_scoring
       AND (SELECT count(*) FROM games.decision_scenario_options o
             WHERE o.scenario_id = s.id AND o.quality = 'OPTIMAL') <> 1;
    IF n <> 0 THEN
        RAISE EXCEPTION '% item(s) notés sans option OPTIMAL unique', n;
    END IF;

    -- Une paire CS est complète ou absente — jamais un seul cadrage.
    SELECT count(*) INTO n FROM (
        SELECT pair_id FROM games.decision_scenarios
         WHERE pair_id IS NOT NULL
         GROUP BY pair_id HAVING count(*) <> 2) p;
    IF n <> 0 THEN
        RAISE EXCEPTION '% paire(s) CS incomplète(s)', n;
    END IF;

    -- Forme A : 30 items, 6 par dimension.
    SELECT count(*) INTO n FROM games.decision_form_items WHERE form_code = 'A';
    IF n <> 30 THEN
        RAISE EXCEPTION 'Forme A : % items au lieu de 30', n;
    END IF;

    SELECT count(*) INTO n FROM (
        SELECT s.dimension
          FROM games.decision_form_items f
          JOIN games.decision_scenarios s ON s.id = f.scenario_id
         WHERE f.form_code = 'A'
         GROUP BY s.dimension HAVING count(*) <> 6) d;
    IF n <> 0 THEN
        RAISE EXCEPTION 'Forme A : % dimension(s) sans 6 items', n;
    END IF;

    -- Toute vignette référencée existe bien dans la banque.
    SELECT count(*) INTO n FROM games.decision_scenarios s
     WHERE s.vignette_ref IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM games.decision_scenarios r
                        WHERE r.item_id = s.vignette_ref
                          AND r.vignette IS NOT NULL);
    IF n <> 0 THEN
        RAISE EXCEPTION '% item(s) référencent une vignette inexistante', n;
    END IF;

    -- Une forme ne peut PAS contenir à la fois un item et celui dont il
    -- réutilise la vignette : l'option OPTIMAL de l'item II énonce la réponse
    -- en clair, ce qui rendrait l'item DT correspondant trivial.
    SELECT count(*) INTO n
      FROM games.decision_form_items f
      JOIN games.decision_scenarios s ON s.id = f.scenario_id
      JOIN games.decision_scenarios r ON r.item_id = s.vignette_ref
      JOIN games.decision_form_items g
        ON g.scenario_id = r.id AND g.form_code = f.form_code;
    IF n <> 0 THEN
        RAISE EXCEPTION
            '% item(s) partagent leur vignette dans une même forme', n;
    END IF;

    -- Aucune paire CS coupée par la composition de la forme.
    SELECT count(*) INTO n FROM (
        SELECT s.pair_id
          FROM games.decision_form_items f
          JOIN games.decision_scenarios s ON s.id = f.scenario_id
         WHERE f.form_code = 'A' AND s.pair_id IS NOT NULL
         GROUP BY s.pair_id HAVING count(*) <> 2) p;
    IF n <> 0 THEN
        RAISE EXCEPTION 'Forme A : % paire(s) CS coupée(s)', n;
    END IF;
END $$;
