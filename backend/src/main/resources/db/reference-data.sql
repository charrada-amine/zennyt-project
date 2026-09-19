-- Données de référence de la base Zennyt.
--
-- Le schéma est généré par Hibernate depuis les entités JPA ; ce script apporte les
-- lignes que l'application attend dès le premier démarrage (référentiel des métiers,
-- banques de contenu des jeux, réglages publiés…). Il est exécuté à chaque démarrage,
-- après la mise à jour du schéma (SchemaComplementsInitializer), mais n'agit qu'UNE
-- FOIS par base : public.seed_history en garde la trace, comme le faisait
-- flyway_schema_history. Une ligne supprimée ou modifiée ensuite par l'administration
-- n'est donc jamais réinsérée ni écrasée.
--
-- Contenu : l'état exact de ces tables après les migrations Flyway V1..V86, extrait
-- d'une base construite par ces migrations. Seules les valeurs que les migrations
-- calculaient à l'exécution restent calculées ici : les identifiants des métiers et
-- des pondérations (gen_random_uuid()) et les horodatages de création/publication
-- (now()).
--
-- Une base déjà migrée par Flyway (présence de public.flyway_schema_history) contient
-- déjà ces données, éventuellement retouchées depuis : le lot y est seulement marqué
-- comme appliqué.
--
-- Pour ajouter des données de référence : un nouveau bloc DO avec un nouveau nom dans
-- seed_history, à la suite de celui-ci — ne jamais modifier un lot déjà appliqué.

DO $seed$
DECLARE
    n INT;
BEGIN
    IF EXISTS (SELECT 1 FROM public.seed_history WHERE name = 'baseline-flyway-v86') THEN
        RETURN;
    END IF;

    IF to_regclass('public.flyway_schema_history') IS NULL THEN
        -- ── Référentiel des métiers (V26, V60) : 142 lignes
        INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, proposed_by_recruiter_id, junior_label, senior_label, lead_label, manager_label, created_at, embedding, suggested_profile_type, type_evaluation_hard) VALUES
            (gen_random_uuid(), 'Acheteur / Buyer', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Actuaire', 'Finance', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Administrateur systèmes & réseaux', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Agent de quai / Magasinier', 'Transport & Mobility', 'CONVENTIONNEL', false, 'APPROVED', NULL, 'Agent débutant', 'Agent confirmé', 'Chef d''équipe quai', 'Responsable entrepôt', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Aide-soignant', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Analyste Cybersécurité', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Analyste Fintech / Quant', 'IT, AI & Fintech', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Analyste crédit', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Analyste environnemental', 'Energy & Sustainable Development', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Analyste financier', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Architecte', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Architecte Solutions', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Assistant consultant / Analyste junior', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Attaché de presse / RP', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Attaché de production', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Auditeur', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Barman / Sommelier', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', NULL, 'Barman débutant', 'Barman confirmé / Sommelier', 'Chef barman', 'Responsable bar', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Bio-informaticien / Data scientist santé', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Brand manager', 'Marketing & Communication', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Business Analyst', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Category manager', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé d''affaires énergie', 'Energy & Sustainable Development', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé d''études', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé d''études marketing', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de communication', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de communication digitale (média)', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de conformité / Compliance officer', 'Finance', 'CONVENTIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de mission', 'Consulting & Services', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de planification transport', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de programmation culturelle', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé de projet RSE', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chargé logistique e-commerce', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de chantier', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de cuisine', 'Hotel & Catering', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de mission conseil', 'Consulting & Services', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de produit marketing', 'Marketing & Communication', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de projet / Product Manager', NULL, 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de rang', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef de rayon', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chef opérateur / Cadreur', 'Media, Culture & Entertainment', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Chercheur biotech', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Commercial / Business Developer', NULL, 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Commis de cuisine', 'Hotel & Catering', 'CONVENTIONNEL', false, 'APPROVED', NULL, 'Commis débutant', 'Commis confirmé / Demi-chef de partie', 'Chef de partie', 'Second de cuisine', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Community manager', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Community manager média', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Compositeur / Sound designer', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Comptable', 'Finance', 'CONVENTIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Concierge', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Conducteur / Chauffeur professionnel', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', NULL, 'Chauffeur débutant', 'Chauffeur confirmé', 'Chauffeur référent / Chef de file', 'Responsable parc', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Conducteur de travaux', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Conseiller clientèle bancaire', 'Finance', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Conseiller de vente', 'Retail & e-commerce', 'RELATIONNEL', false, 'APPROVED', NULL, 'Conseiller débutant', 'Conseiller confirmé', 'Conseiller référent', 'Adjoint responsable magasin', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Consultant', NULL, 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Consultant RH', 'Consulting & Services', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Consultant SI / Digital', 'Consulting & Services', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Consultant en organisation', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Consultant financier', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Content manager / Rédacteur', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Contrôleur de gestion', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Contrôleur de gestion transport', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Data Analyst / Data Scientist', NULL, 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Data Engineer', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Directeur artistique', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Directeur d''hôtel', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Développeur', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Finance / Comptabilité', NULL, 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Gestionnaire de portefeuille / Asset manager', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Gestionnaire de stock', 'Retail & e-commerce', 'CONVENTIONNEL', false, 'APPROVED', NULL, 'Gestionnaire stock débutant', 'Gestionnaire stock confirmé', 'Chef d''équipe logistique', 'Responsable entrepôt', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Gouvernante générale', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Graphiste / Designer', 'Marketing & Communication', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Growth hacker', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Illustrateur / Concept artist', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Infirmier', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur BTP', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur Blockchain', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur DevOps / Cloud', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur IA / Machine Learning', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur QA / Testeur', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur R&D industriel', 'Industry', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur biomédical', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur de production', 'Industry', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur efficacité énergétique', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur logistique', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur mobilité / transport', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur méthodes', 'Industry', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur process', 'Industry', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur structure', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur énergie', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ingénieur énergies renouvelables', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Journaliste', 'Media, Culture & Entertainment', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Kinésithérapeute', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Management général / Direction', NULL, 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Marketing / Communication', NULL, 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Merchandiser', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Monteur / Technicien audiovisuel', 'Media, Culture & Entertainment', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Motion designer', 'Marketing & Communication', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'MIXTE'),
            (gen_random_uuid(), 'Médecin', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Métreur', 'Construction & Infrastructure', 'CONVENTIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Opérateur de production', 'Industry', 'CONVENTIONNEL', false, 'APPROVED', NULL, 'Opérateur débutant', 'Opérateur confirmé', 'Chef d''équipe production', 'Chef d''atelier', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Ouvrier / Compagnon qualifié', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', NULL, 'Apprenti / Ouvrier débutant', 'Compagnon confirmé', 'Chef d''équipe', 'Chef de chantier', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Pharmacien', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Photographe', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Pilote / Agent navigant', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', NULL, 'Copilote', 'Commandant de bord confirmé', 'Commandant de bord senior', 'Chef pilote', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Product Owner', 'IT, AI & Fintech', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'RH / Talent Acquisition', NULL, 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable HSE', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable HSE chantier', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable HSE industriel', 'Industry', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable affaires réglementaires santé', 'Health & Biotech', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable d''atelier / production', 'Industry', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable de magasin', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable développement durable', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable e-commerce', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable exploitation transport', 'Transport & Mobility', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable logistique', 'Transport & Mobility', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable qualité', 'Industry', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable restauration (F&B manager)', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Responsable supply chain', 'Industry', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Risk Manager', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Réalisateur / Producteur', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Réceptionniste', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Régisseur', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'SEO specialist', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Sage-femme', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Scrum Master / Agile Coach', 'IT, AI & Fintech', 'MANAGERIAL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Scénariste', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Serveur / Maître d''hôtel', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', NULL, 'Serveur débutant', 'Serveur confirmé', 'Chef de rang', 'Maître d''hôtel', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Styliste / Designer produit', 'Retail & e-commerce', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'PORTFOLIO'),
            (gen_random_uuid(), 'Support client / Service client', NULL, 'RELATIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien bureau d''études', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien de laboratoire', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien de maintenance', 'Industry', 'TECHNIQUE', false, 'APPROVED', NULL, 'Technicien débutant', 'Technicien confirmé', 'Technicien référent / Chef d''équipe', 'Responsable maintenance', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien maintenance flotte', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', NULL, 'Technicien débutant', 'Technicien confirmé', 'Technicien référent / Chef d''équipe', 'Responsable maintenance flotte', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien photovoltaïque / éolien', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien qualité', 'Industry', 'CONVENTIONNEL', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Technicien réseaux énergie', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', NULL, 'Technicien débutant', 'Technicien confirmé', 'Technicien référent / Chef d''équipe', 'Responsable réseaux', now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Trader', 'Finance', 'TECHNIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Traffic manager / SEA specialist', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'Trésorier', 'Finance', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM'),
            (gen_random_uuid(), 'UX/UI Designer', 'IT, AI & Fintech', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'MIXTE'),
            (gen_random_uuid(), 'UX/UI e-commerce', 'Retail & e-commerce', 'ARTISTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'MIXTE'),
            (gen_random_uuid(), 'Économiste de la construction', 'Construction & Infrastructure', 'ANALYTIQUE', false, 'APPROVED', NULL, NULL, NULL, NULL, NULL, now(), NULL, NULL, 'QCM');

        -- ── Pondérations Fit Score par type de profil et niveau (V42, V53) : 24 lignes
        INSERT INTO recruitment.job_role_profiles (id, profile_type, level, soft_weight, hard_weight, expected_hard_weight, cognitive_flexibility_weight, working_memory_weight, decision_making_weight, executive_planning_weight, emotional_regulation_weight, calibrated, updated_at) VALUES
            (gen_random_uuid(), 'ANALYTIQUE', 'JUNIOR', 70, 30, 30, 25, 20, 30, 15, 10, false, now()),
            (gen_random_uuid(), 'ANALYTIQUE', 'LEAD', 50, 50, 50, 25, 20, 30, 15, 10, false, now()),
            (gen_random_uuid(), 'ANALYTIQUE', 'MANAGER', 75, 25, 25, 25, 20, 30, 15, 10, false, now()),
            (gen_random_uuid(), 'ANALYTIQUE', 'SENIOR', 40, 60, 60, 25, 20, 30, 15, 10, false, now()),
            (gen_random_uuid(), 'ARTISTIQUE', 'JUNIOR', 70, 30, 30, 40, 15, 15, 15, 15, false, now()),
            (gen_random_uuid(), 'ARTISTIQUE', 'LEAD', 55, 45, 45, 40, 15, 15, 15, 15, false, now()),
            (gen_random_uuid(), 'ARTISTIQUE', 'MANAGER', 75, 25, 25, 40, 15, 15, 15, 15, false, now()),
            (gen_random_uuid(), 'ARTISTIQUE', 'SENIOR', 45, 55, 55, 40, 15, 15, 15, 15, false, now()),
            (gen_random_uuid(), 'CONVENTIONNEL', 'JUNIOR', 75, 25, 25, 15, 30, 15, 30, 10, false, now()),
            (gen_random_uuid(), 'CONVENTIONNEL', 'LEAD', 65, 35, 35, 15, 30, 15, 30, 10, false, now()),
            (gen_random_uuid(), 'CONVENTIONNEL', 'MANAGER', 80, 20, 20, 15, 30, 15, 30, 10, false, now()),
            (gen_random_uuid(), 'CONVENTIONNEL', 'SENIOR', 60, 40, 40, 15, 30, 15, 30, 10, false, now()),
            (gen_random_uuid(), 'MANAGERIAL', 'JUNIOR', 80, 20, 20, 10, 10, 20, 30, 30, false, now()),
            (gen_random_uuid(), 'MANAGERIAL', 'LEAD', 65, 35, 35, 10, 10, 20, 30, 30, false, now()),
            (gen_random_uuid(), 'MANAGERIAL', 'MANAGER', 80, 20, 20, 10, 10, 20, 30, 30, false, now()),
            (gen_random_uuid(), 'MANAGERIAL', 'SENIOR', 60, 40, 40, 10, 10, 20, 30, 30, false, now()),
            (gen_random_uuid(), 'RELATIONNEL', 'JUNIOR', 90, 10, 10, 10, 10, 20, 15, 45, false, now()),
            (gen_random_uuid(), 'RELATIONNEL', 'LEAD', 80, 20, 20, 10, 10, 20, 15, 45, false, now()),
            (gen_random_uuid(), 'RELATIONNEL', 'MANAGER', 90, 10, 10, 10, 10, 20, 15, 45, false, now()),
            (gen_random_uuid(), 'RELATIONNEL', 'SENIOR', 75, 25, 25, 10, 10, 20, 15, 45, false, now()),
            (gen_random_uuid(), 'TECHNIQUE', 'JUNIOR', 65, 35, 35, 30, 20, 30, 15, 5, false, now()),
            (gen_random_uuid(), 'TECHNIQUE', 'LEAD', 45, 55, 55, 30, 20, 30, 15, 5, false, now()),
            (gen_random_uuid(), 'TECHNIQUE', 'MANAGER', 70, 30, 30, 30, 20, 30, 15, 5, false, now()),
            (gen_random_uuid(), 'TECHNIQUE', 'SENIOR', 35, 65, 65, 30, 20, 30, 15, 5, false, now());

        -- ── « Je Décide » — banque des 120 items du psychologue (V67) : 120 lignes
        INSERT INTO games.decision_scenarios (id, item_id, dimension, format, pair_id, vignette, vignette_ref, task, optimal_option, provisional_scoring, "position", created_at, updated_at) VALUES
            ('02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15', 'RE', 'STANDARD', NULL, 'Une offre s''affiche avec compte à rebours et message : « 50 € maintenant — 30 secondes » vs 80 € dans 10 jours sans contrainte de temps.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 15, now(), now()),
            ('037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15', 'ER', 'STANDARD', NULL, 'Option X : 70 € garantis. Option Y : 50 % de chance de gagner 160 €, 50 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 15, now(), now()),
            ('05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-2', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 2, now(), now()),
            ('079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-21', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 21, now(), now()),
            ('07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b', 'CS', 'COHERENCE_PAIR', 'CS-10', 'CS-10b — Cadrage PERTE
Plan A : 120 000 dossiers clients seront compromis de façon certaine.
Plan B : 1 chance sur 3 qu''aucun dossier ne soit compromis, 2 chances sur 3 que les 180 000 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 20, now(), now()),
            ('0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13', 'II', 'STANDARD', NULL, 'Vous choisissez un déménageur. Trois options : A (tarif dans le budget, assurance couvrant la valeur totale des biens, disponible dans 2 semaines), B (moins cher, assurance plafonnée à 50% de la valeur des biens, disponible immédiatement), C (cher, hors budget, assurance totale, disponible la semaine prochaine). Budget plafonné ; assurance couvrant 100% de la valeur obligatoire.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 13, now(), now()),
            ('0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-9', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 9, now(), now()),
            ('0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19', 'II', 'STANDARD', NULL, 'Vous cherchez un local commercial pour ouvrir un cabinet paramédical recevant du public à mobilité réduite. Trois locaux : A (loyer dans votre budget, accès de plain-pied avec rampe PMR conforme), B (loyer moins cher, accès par un escalier de 3 marches, aucune rampe), C (loyer élevé, dépasse votre budget, accès PMR conforme avec ascenseur). Votre budget est plafonné et l''accessibilité PMR est une obligation réglementaire pour votre activité.', NULL, 'Classez les trois locaux du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 19, now(), now()),
            ('11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a', 'CS', 'COHERENCE_PAIR', 'CS-1', 'CS-1a — Cadrage GAIN
Plan A : 200 emplois sauvés de façon certaine.
Plan B : 1 chance sur 3 que les 600 emplois soient sauvés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 1, now(), now()),
            ('14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1', 'RE', 'STANDARD', NULL, 'Option immédiate : 10 € maintenant. Option différée : 25 € dans 7 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 1, now(), now()),
            ('1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-1', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 1, now(), now()),
            ('18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-15', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 15, now(), now()),
            ('19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 300 €. Option Y : 60 % de chance de perdre 600 €, 40 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 12, now(), now()),
            ('1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a', 'CS', 'COHERENCE_PAIR', 'CS-8', 'CS-8a — Cadrage GAIN
Plan A : 30 000 € préservés de façon certaine.
Plan B : 1 chance sur 3 de préserver les 90 000 €, 2 chances sur 3 de tout perdre.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 15, now(), now()),
            ('1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b', 'CS', 'COHERENCE_PAIR', 'CS-11', 'CS-11b — Cadrage PERTE
Plan A : 160 élèves sur 240 échoueront leur année de façon certaine.
Plan B : 1 chance sur 3 qu''aucun élève n''échoue, 2 chances sur 3 que les 240 échouent.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 22, now(), now()),
            ('27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21', 'II', 'STANDARD', NULL, 'Vous cherchez une pension pour votre chien pendant vos vacances. Trois options : A (moins chère, pas de vétérinaire sur place), B (chère, dépasse votre budget, vétérinaire sur place), C (tarif dans votre budget, vétérinaire sur place). Votre budget est plafonné et un vétérinaire doit être disponible sur place en raison d''un traitement médical en cours.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 21, now(), now()),
            ('2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b', 'CS', 'COHERENCE_PAIR', 'CS-1', 'CS-1b — Cadrage PERTE
Plan A : 400 emplois perdus de façon certaine.
Plan B : 1 chance sur 3 qu''aucun emploi ne soit perdu, 2 chances sur 3 que les 600 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 2, now(), now()),
            ('308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b', 'CS', 'COHERENCE_PAIR', 'CS-4', 'CS-4b — Cadrage PERTE
Plan A : 200 accidents surviendront de façon certaine.
Plan B : 1 chance sur 3 qu''aucun accident ne survienne, 2 chances sur 3 que les 300 surviennent.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 8, now(), now()),
            ('3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2', 'ER', 'STANDARD', NULL, 'Option X : 30 € garantis. Option Y : 50 % de chance de gagner 70 €, 50 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 2, now(), now()),
            ('33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3', 'II', 'STANDARD', NULL, 'Vous cherchez un appartement à louer. Trois options : A (loyer dans le plafond, trajet 25 min, quartier calme), B (loyer bas, trajet 50 min, quartier très calme), C (loyer élevé, dépassant votre plafond, trajet 10 min, quartier animé). Plafond de loyer fixe, trajet ≤ 30 min exigé. Le calme du quartier est un critère secondaire non éliminatoire.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 3, now(), now()),
            ('34e56502-0331-5190-a2d9-3dde31752808', 'II-10', 'II', 'STANDARD', NULL, 'Vous sélectionnez un logiciel de gestion de projet pour votre équipe de 12 personnes. Trois options : A (moins cher, incompatible avec votre messagerie et votre CRM actuels), B (licence dans le budget, compatible avec la messagerie uniquement), C (prix dans le budget, compatible messagerie et CRM). Budget plafonné ; compatibilité totale avec l''environnement existant requise.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 10, now(), now()),
            ('364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a', 'CS', 'COHERENCE_PAIR', 'CS-9', 'CS-9a — Cadrage GAIN
Plan A : 300 salariés protégés de façon certaine.
Plan B : 1 chance sur 3 de protéger les 900 salariés, 2 chances sur 3 de n''en protéger aucun.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 17, now(), now()),
            ('38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a', 'CS', 'COHERENCE_PAIR', 'CS-4', 'CS-4a — Cadrage GAIN
Plan A : 100 accidents évités de façon certaine.
Plan B : 1 chance sur 3 d''éviter les 300 accidents, 2 chances sur 3 de n''en éviter aucun.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 7, now(), now()),
            ('3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21', 'RE', 'STANDARD', NULL, 'Une offre s''affiche avec un compte à rebours : « 30 € maintenant, offre valable 20 secondes » (urgence visuelle marquée) vs 45 € dans 5 jours sans contrainte de temps.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 21, now(), now()),
            ('3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2', 'II', 'STANDARD', NULL, 'Vous choisissez un smartphone pour un usage professionnel avec déplacements fréquents. Trois modèles : A (prix moyen, autonomie 2 jours, design correct), B (prix bas, autonomie 1 jour, bonnes critiques), C (cher, dépassant votre budget, autonomie 3 jours). Budget limité, autonomie ≥ 2 jours requise.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 2, now(), now()),
            ('4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7', 'II', 'STANDARD', NULL, 'Vous achetez une voiture pour des trajets professionnels réguliers de 250 km. Trois modèles : A (dans le budget, autonomie 550 km, consommation standard), B (moins cher, autonomie 280 km, faible consommation), C (cher, hors budget, autonomie 700 km, faible consommation). Budget plafonné ; autonomie ≥ 500 km requise pour les trajets sans rechargement.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 7, now(), now()),
            ('44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 40 €. Option Y : 50 % de chance de perdre 100 €, 50 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 20, now(), now()),
            ('48c98228-9651-52c0-b294-373733227320', 'RE-6', 'RE', 'STANDARD', NULL, 'Option immédiate : 20 € maintenant. Option différée : 60 € dans 60 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 6, now(), now()),
            ('4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3', 'RE', 'STANDARD', NULL, 'Option immédiate : 5 € maintenant. Option différée : 12 € dans 3 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 3, now(), now()),
            ('4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a', 'CS', 'COHERENCE_PAIR', 'CS-7', 'CS-7a — Cadrage GAIN
Plan A : 300 hectares préservés de façon certaine.
Plan B : 1 chance sur 3 de préserver les 900 hectares, 2 chances sur 3 de n''en préserver aucun.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 13, now(), now()),
            ('524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4', 'ER', 'STANDARD', NULL, 'Option X : 100 € garantis. Option Y : 25 % de chance de gagner 450 €, 75 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 4, now(), now()),
            ('554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a', 'CS', 'COHERENCE_PAIR', 'CS-12', 'CS-12a — Cadrage GAIN
Plan A : 100 000 foyers seront épargnés par la coupure de façon certaine.
Plan B : 1 chance sur 3 que les 300 000 foyers soient épargnés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 23, now(), now()),
            ('554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 20 €. Option Y : 50 % de chance de perdre 50 €, 50 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 5, now(), now()),
            ('557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19', 'ER', 'STANDARD', NULL, 'Option X : 60 € garantis. Option Y : 50 % de chance de gagner 150 €, 50 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 19, now(), now()),
            ('577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b', 'CS', 'COHERENCE_PAIR', 'CS-2', 'CS-2b — Cadrage PERTE
Option A : perdre 3 000 € de façon certaine.
Option B : 70 % de chance de ne rien perdre, 30 % de chance de tout perdre.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 4, now(), now()),
            ('58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21', 'ER', 'STANDARD', NULL, 'Option X : 120 € garantis. Option Y : 40 % de chance de gagner 350 €, 60 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 21, now(), now()),
            ('5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a', 'CS', 'COHERENCE_PAIR', 'CS-10', 'CS-10a — Cadrage GAIN
Plan A : 60 000 dossiers clients seront protégés de façon certaine.
Plan B : 1 chance sur 3 que les 180 000 dossiers soient protégés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 19, now(), now()),
            ('61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 150 €. Option Y : 30 % de chance de perdre 600 €, 70 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 18, now(), now()),
            ('63650717-5648-5191-91c5-244cbaa017f6', 'DT-10', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-10', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 10, now(), now()),
            ('64b551c7-e5af-5465-ae08-c936819eb146', 'II-17', 'II', 'STANDARD', NULL, 'Vous réservez une salle pour une conférence annuelle (140 participants). Trois options : A (dans le budget, capacité 150 personnes, équipement audiovisuel standard, parking 30 places), B (moins cher, capacité 90 personnes, bon équipement AV, proche transports en commun), C (cher, hors budget, capacité 250 personnes, équipement AV haut de gamme, parking 100 places). Budget plafonné ; capacité ≥ 140 personnes obligatoire.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 17, now(), now()),
            ('64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22', 'II', 'STANDARD', NULL, 'Vous choisissez un fournisseur d''électricité pour votre entreprise. Trois offres : A (tarif dans votre budget, électricité certifiée 100 % renouvelable), B (chère, dépasse votre budget, électricité certifiée 100 % renouvelable), C (moins chère, électricité non certifiée renouvelable). Votre budget est plafonné et la certification 100 % renouvelable est exigée par votre charte RSE.', NULL, 'Classez les trois offres de la plus à la moins adaptée, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 22, now(), now()),
            ('67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23', 'ER', 'STANDARD', NULL, 'Option X : 45 € garantis. Option Y : 25 % de chance de gagner 200 €, 75 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 23, now(), now()),
            ('68173ddd-63fd-5019-a6db-409620345268', 'RE-14', 'RE', 'STANDARD', NULL, 'Option immédiate : 40 € maintenant. Option différée : 70 € dans 14 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 14, now(), now()),
            ('6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 100 €. Option Y : 50 % de chance de perdre 220 €, 50 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 16, now(), now()),
            ('6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-14', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 14, now(), now()),
            ('6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9', 'II', 'STANDARD', NULL, 'Vous choisissez une salle de sport. Trois options : A (moins chère, à 40 min de trajet, équipements récents), B (chère, hors budget, à 5 min, équipements récents), C (dans le budget, à 12 min, équipements corrects). Budget plafonné ; distance ≤ 15 min.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 9, now(), now()),
            ('6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17', 'ER', 'STANDARD', NULL, 'Option X : 1 000 € garantis. Option Y : 30 % de chance de gagner 4 000 €, 70 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 17, now(), now()),
            ('704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-23', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 23, now(), now()),
            ('715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5', 'II', 'STANDARD', NULL, 'Vous organisez un repas d''affaires. Trois restaurants : A (cher, hors budget, ambiance calme, note 4.8/5), B (pas cher, dans le budget, très bruyant, note 4.5/5), C (prix dans le budget, ambiance calme, note 4.2/5). Budget plafonné ; conversation professionnelle requérant calme.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 5, now(), now()),
            ('71b34741-0338-5fb6-aade-816894f23a66', 'DT-11', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-11', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 11, now(), now()),
            ('72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12', 'II', 'STANDARD', NULL, 'Vous choisissez une formation professionnelle certifiante. Trois options : A (moins chère, format journée incompatible avec votre emploi du temps, reconnue par votre secteur), B (tarif dans le budget, format soirée compatible, reconnaissance sectorielle identique à A), C (chère, hors budget, format soirée, reconnue internationalement). Budget plafonné ; format compatible avec emploi du temps actuel.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 12, now(), now()),
            ('75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10', 'RE', 'STANDARD', NULL, 'Option immédiate : 100 € maintenant. Option différée : 180 € dans 45 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 10, now(), now()),
            ('785021ff-1130-5225-ae9a-0290603803aa', 'DT-19', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-19', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 19, now(), now()),
            ('7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7', 'ER', 'STANDARD', NULL, 'Option X : 40 € garantis. Option Y : 20 % de chance de gagner 250 €, 80 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 7, now(), now()),
            ('7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-20', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 20, now(), now()),
            ('7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13', 'ER', 'STANDARD', NULL, 'Option X : 25 € garantis. Option Y : 10 % de chance de gagner 300 €, 90 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 13, now(), now()),
            ('7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b', 'CS', 'COHERENCE_PAIR', 'CS-6', 'CS-6b — Cadrage PERTE
Plan A : 600 tonnes perdues de façon certaine.
Plan B : 1 chance sur 3 qu''aucune tonne ne soit perdue, 2 chances sur 3 que les 900 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 12, now(), now()),
            ('8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7', 'RE', 'STANDARD', NULL, 'Option immédiate : 8 € maintenant. Option différée : 20 € dans 5 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 7, now(), now()),
            ('8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17', 'RE', 'STANDARD', NULL, 'Option immédiate : 3 € maintenant. Option différée : 8 € dans 4 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 17, now(), now()),
            ('86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-7', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 7, now(), now()),
            ('87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4', 'II', 'STANDARD', NULL, 'Vous recevez trois offres d''emploi : A (CDI, salaire légèrement sous votre seuil minimum), B (CDD 18 mois, salaire 15% au-dessus de votre seuil, secteur porteur), C (CDI, salaire au seuil exact, poste avec perspectives d''évolution mentionnées dans l''offre). Priorité à la stabilité contractuelle ; le salaire doit atteindre le seuil minimum.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 4, now(), now()),
            ('881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9', 'RE', 'STANDARD', NULL, 'Option immédiate : 12 € maintenant. Option différée : 30 € dans 10 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 9, now(), now()),
            ('8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9', 'ER', 'STANDARD', NULL, 'Option X : 15 € garantis. Option Y : 50 % de chance de gagner 40 €, 50 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 9, now(), now()),
            ('8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b', 'CS', 'COHERENCE_PAIR', 'CS-8', 'CS-8b — Cadrage PERTE
Plan A : perdre 60 000 € de façon certaine.
Plan B : 1 chance sur 3 de ne rien perdre, 2 chances sur 3 de tout perdre.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 16, now(), now()),
            ('9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5', 'RE', 'STANDARD', NULL, 'Une offre s''affiche avec un compte à rebours visuel : « 10 € maintenant — 10 secondes restantes » (rouge clignotant) vs 15 € dans 2 jours sans contrainte de temps.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 5, now(), now()),
            ('908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b', 'CS', 'COHERENCE_PAIR', 'CS-12', 'CS-12b — Cadrage PERTE
Plan A : 200 000 foyers sur 300 000 subiront une coupure de façon certaine.
Plan B : 1 chance sur 3 qu''aucun foyer ne subisse de coupure, 2 chances sur 3 que les 300 000 la subissent.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 24, now(), now()),
            ('91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b', 'CS', 'COHERENCE_PAIR', 'CS-3', 'CS-3b — Cadrage PERTE
Plan A : la santé de 600 employés se dégradera de façon certaine.
Plan B : 1 chance sur 3 qu''aucun employé ne soit affecté, 2 chances sur 3 que les 900 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 6, now(), now()),
            ('93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-8', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 8, now(), now()),
            ('94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6', 'II', 'STANDARD', NULL, 'Vous choisissez une mutuelle santé. Trois offres : A (prime élevée, hors budget, couverture complète), B (prime basse, dans le budget, couverture insuffisante pour un antécédent médical connu), C (prime dans le budget, couverture adaptée à l''antécédent, délai de remboursement 30 jours). Budget serré ; couverture de l''antécédent obligatoire.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 6, now(), now()),
            ('984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-12', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 12, now(), now()),
            ('9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a', 'CS', 'COHERENCE_PAIR', 'CS-5', 'CS-5a — Cadrage GAIN
Plan A : 30 salariés seront formés de façon certaine.
Plan B : 1 chance sur 3 que les 90 soient formés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 9, now(), now()),
            ('9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 250 €. Option Y : 40 % de chance de perdre 700 €, 60 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 24, now(), now()),
            ('a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2', 'RE', 'STANDARD', NULL, 'Option immédiate : 15 € maintenant. Option différée : 40 € dans 14 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 2, now(), now()),
            ('a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24', 'RE', 'STANDARD', NULL, 'Option immédiate : 150 € maintenant. Option différée : 260 € dans 50 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 24, now(), now()),
            ('a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23', 'II', 'STANDARD', NULL, 'Vous cherchez un avocat pour un litige commercial complexe. Trois cabinets : A (honoraires dans votre budget, spécialisé en droit commercial), B (moins cher, généraliste sans spécialisation en droit commercial), C (cher, dépasse votre budget, spécialisé en droit commercial). Votre budget est plafonné et la spécialisation en droit commercial est indispensable pour ce dossier.', NULL, 'Classez les trois cabinets du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 23, now(), now()),
            ('a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-22', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 22, now(), now()),
            ('a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-4', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 4, now(), now()),
            ('a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-16', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 16, now(), now()),
            ('a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14', 'II', 'STANDARD', NULL, 'Vous choisissez un forfait internet pour le télétravail intensif (visioconférences quotidiennes, transferts de fichiers lourds). Trois options : A (moins cher, débit moyen 20 Mb/s, suffisant pour la navigation mais insuffisant pour la visio HD), B (tarif dans le budget, débit 100 Mb/s, compatible visio HD), C (cher, hors budget, débit 500 Mb/s, fibre optique). Budget plafonné ; débit ≥ 50 Mb/s requis pour les usages professionnels.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 14, now(), now()),
            ('a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-18', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'B', false, 18, now(), now()),
            ('a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22', 'RE', 'STANDARD', NULL, 'Option immédiate : 60 € maintenant. Option différée : 110 € dans 40 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 22, now(), now()),
            ('ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 50 €. Option Y : 50 % de chance de perdre 120 €, 50 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 3, now(), now()),
            ('abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-13', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 13, now(), now()),
            ('b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 10 €. Option Y : 50 % de chance de perdre 25 €, 50 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 10, now(), now()),
            ('b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-5', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 5, now(), now()),
            ('b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18', 'RE', 'STANDARD', NULL, 'Option immédiate : 200 € maintenant. Option différée : 320 € dans 60 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 18, now(), now()),
            ('b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16', 'RE', 'STANDARD', NULL, 'Option immédiate : 18 € maintenant. Option différée : 45 € dans 30 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 16, now(), now()),
            ('b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b', 'CS', 'COHERENCE_PAIR', 'CS-5', 'CS-5b — Cadrage PERTE
Plan A : 60 salariés resteront sans formation de façon certaine.
Plan B : 1 chance sur 3 que tous soient formés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 10, now(), now()),
            ('b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-3', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 3, now(), now()),
            ('bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8', 'II', 'STANDARD', NULL, 'Vous cherchez une crèche pour votre enfant. Trois options : A (tarif bas, horaires 9h–17h, projet pédagogique bilingue), B (tarif dans le budget, horaires 7h30–19h, projet pédagogique standard), C (tarif élevé, hors budget, horaires 7h–20h, projet pédagogique bilingue). Budget plafonné ; horaires devant couvrir 8h–18h30.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 8, now(), now()),
            ('bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23', 'RE', 'STANDARD', NULL, 'Option immédiate : 9 € maintenant. Option différée : 22 € dans 6 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 23, now(), now()),
            ('bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a', 'CS', 'COHERENCE_PAIR', 'CS-6', 'CS-6a — Cadrage GAIN
Plan A : 300 tonnes préservées de façon certaine.
Plan B : 1 chance sur 3 de préserver les 900 tonnes, 2 chances sur 3 de n''en préserver aucune.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 11, now(), now()),
            ('bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 80 €. Option Y : 90 % de chance de perdre 100 €, 10 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 8, now(), now()),
            ('bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19', 'RE', 'STANDARD', NULL, 'Option immédiate : 7 € maintenant. Option différée : 18 € dans 6 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 19, now(), now()),
            ('bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11', 'II', 'STANDARD', NULL, 'Vous sélectionnez un fournisseur pour un contrat annuel. Trois options : A (tarif bas, délai livraison 18 jours, certifié ISO 9001), B (cher, hors budget, délai 3 jours, certifié ISO 9001), C (dans le budget, délai 6 jours, en cours de certification ISO). Budget plafonné ; délai ≤ 7 jours exigé contractuellement.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 11, now(), now()),
            ('c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4', 'RE', 'STANDARD', NULL, 'Option immédiate : 50 € maintenant. Option différée : 100 € dans 30 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 4, now(), now()),
            ('c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15', 'II', 'STANDARD', NULL, 'Vous choisissez un espace de coworking pour votre équipe de 4 personnes. Trois options : A (moins cher, open space uniquement, pas de salle de réunion réservable), B (cher, hors budget, salles privatives réservables, accès 24h/24), C (dans le budget, salles de réunion réservables 4h/semaine incluses, accès standard 8h–20h). Budget plafonné ; au moins une salle de réunion réservable requise hebdomadairement.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 15, now(), now()),
            ('ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1', 'ER', 'STANDARD', NULL, 'Option X : 50 € garantis. Option Y : 60 % de chance de gagner 90 €, 40 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 1, now(), now()),
            ('d2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-17', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'A', false, 17, now(), now()),
            ('d7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18', 'II', 'STANDARD', NULL, 'Vous choisissez un ordinateur portable pour un graphiste de votre équipe (travail sur logiciels de retouche photo et montage vidéo). Trois options : A (moins cher, RAM 8 Go, GPU intégré, performances insuffisantes pour le montage vidéo 4K), B (dans le budget, RAM 16 Go, GPU dédié 4 Go, compatible avec les logiciels métiers), C (cher, hors budget, RAM 32 Go, GPU dédié 8 Go, performances maximales). Budget plafonné ; performances compatibles avec les logiciels métiers obligatoires.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 18, now(), now()),
            ('d93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1', 'II', 'STANDARD', NULL, 'Vous préparez un déplacement professionnel. Trois hôtels : A (prix bas, à 30 min à pied du lieu de rendez-vous, avis mixtes), B (prix moyen, à 8 min à pied, bonnes notes), C (cher, dépassant votre budget, à 5 min, note excellente). Votre budget ne doit pas dépasser le tarif moyen et le trajet ne doit pas excéder 10 minutes à pied.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 1, now(), now()),
            ('da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b', 'CS', 'COHERENCE_PAIR', 'CS-9', 'CS-9b — Cadrage PERTE
Plan A : 600 salariés touchés de façon certaine.
Plan B : 1 chance sur 3 qu''aucun salarié ne soit touché, 2 chances sur 3 que les 900 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 18, now(), now()),
            ('dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20', 'II', 'STANDARD', NULL, 'Vous devez louer un camion pour un déménagement professionnel. Trois véhicules : A (tarif dans votre budget, nécessite un permis B classique que vous détenez), B (moins cher, nécessite un permis C1 que vous ne détenez pas), C (cher, dépasse votre budget, nécessite un permis B classique). Votre budget est plafonné et vous ne pouvez conduire qu''avec le permis B que vous détenez.', NULL, 'Classez les trois véhicules du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 20, now(), now()),
            ('de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a', 'CS', 'COHERENCE_PAIR', 'CS-2', 'CS-2a — Cadrage GAIN
Option A : conserver 7 000 € de façon certaine.
Option B : 70 % de chance de conserver les 10 000 €, 30 % de chance de tout perdre.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 3, now(), now()),
            ('e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6', 'ER', 'STANDARD', NULL, 'Option X : 200 € garantis. Option Y : 80 % de chance de gagner 270 €, 20 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 6, now(), now()),
            ('e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 5 €. Option Y : 10 % de chance de perdre 60 €, 90 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 14, now(), now()),
            ('e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a', 'CS', 'COHERENCE_PAIR', 'CS-11', 'CS-11a — Cadrage GAIN
Plan A : 80 élèves réussiront leur année de façon certaine.
Plan B : 1 chance sur 3 que les 240 élèves réussissent, 2 chances sur 3 qu''aucun ne réussisse.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 21, now(), now()),
            ('e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22', 'ER', 'STANDARD', NULL, 'Option X : perte certaine de 60 €. Option Y : 70 % de chance de perdre 100 €, 30 % de chance de ne rien perdre.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, false, 22, now(), now()),
            ('e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24', 'II', 'STANDARD', NULL, 'Vous choisissez un prestataire pour le nettoyage de vos entrepôts en hauteur. Trois prestataires : A (tarif dans votre budget, équipe habilitée travail en hauteur), B (moins cher, équipe non habilitée travail en hauteur), C (cher, dépasse votre budget, équipe habilitée travail en hauteur). Votre budget est plafonné et l''habilitation travail en hauteur est une obligation légale pour cette prestation.', NULL, 'Classez les trois prestataires du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 24, now(), now()),
            ('e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11', 'ER', 'STANDARD', NULL, 'Option X : 500 € garantis. Option Y : 60 % de chance de gagner 900 €, 40 % de chance de gagner 0 €.', NULL, 'Choisissez l''option X ou l''option Y.', NULL, true, 11, now(), now()),
            ('e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b', 'CS', 'COHERENCE_PAIR', 'CS-7', 'CS-7b — Cadrage PERTE
Plan A : 600 hectares dégradés de façon certaine.
Plan B : 1 chance sur 3 qu''aucun hectare ne soit dégradé, 2 chances sur 3 que les 900 le soient.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 14, now(), now()),
            ('e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12', 'RE', 'STANDARD', NULL, 'Option immédiate : 30 € maintenant. Option différée : 90 € dans 90 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 12, now(), now()),
            ('ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-24', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 24, now(), now()),
            ('ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13', 'RE', 'STANDARD', NULL, 'Option immédiate : 6 € maintenant. Option différée : 8 € dans 2 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 13, now(), now()),
            ('f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11', 'RE', 'STANDARD', NULL, 'Une offre flash s''affiche : « 20 € maintenant — 15 secondes restantes » (bandeau rouge) vs 35 € dans 3 jours sans contrainte de temps.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 11, now(), now()),
            ('f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16', 'II', 'STANDARD', NULL, 'Vous choisissez un traiteur pour un séminaire d''entreprise (80 personnes, dont 12 avec allergies au gluten et 5 végétariens). Trois options : A (moins cher, menus standards, pas d''option sans gluten ni végétarienne), B (dans le budget, menus adaptés gluten et végétarien, service assis), C (cher, hors budget, menus gastronomiques avec toutes adaptations, service à table). Budget plafonné ; menus adaptés obligatoires pour l''ensemble des régimes présents.', NULL, 'Classez les trois options du plus au moins adapté, puis choisissez la justification qui reflète le mieux votre raisonnement.', NULL, false, 16, now(), now()),
            ('f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6', 'DT', 'TEMPORAL_DECISION', NULL, NULL, 'II-6', 'Vous disposez de 7 secondes pour choisir l''option A, B ou C.', 'C', false, 6, now(), now()),
            ('f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a', 'CS', 'COHERENCE_PAIR', 'CS-3', 'CS-3a — Cadrage GAIN
Plan A : 300 employés préservent leur santé de façon certaine.
Plan B : 1 chance sur 3 que les 900 soient préservés, 2 chances sur 3 qu''aucun ne le soit.', NULL, 'Choisissez le Plan A ou le Plan B.', NULL, true, 5, now(), now()),
            ('fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8', 'RE', 'STANDARD', NULL, 'Option immédiate : 25 € maintenant. Option différée : 55 € dans 21 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 8, now(), now()),
            ('fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20', 'RE', 'STANDARD', NULL, 'Option immédiate : 22 € maintenant. Option différée : 50 € dans 20 jours.', NULL, 'Choisissez l''option immédiate ou l''option différée.', NULL, true, 20, now(), now());

        -- ── « Je Décide » — options de réponse et clé de correction (V67) : 324 lignes
        INSERT INTO games.decision_scenario_options (id, scenario_id, option_id, label, quality, "position") VALUES
            ('00a12257-5311-52d9-b463-3e18cc26d29b', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-A', 'Option A', 'OPTIMAL', 1),
            ('00fc30d9-d29c-5a55-a2f6-7ea571a8bde3', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o4', 'Je choisis A car le nom du poste correspond exactement à ma formation.', 'DEFICIENT', 4),
            ('024a4b0f-c5cc-5db1-9ba5-be77f1b97fb3', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o2', 'Je choisis A car l''électricité me semble verte.', 'SATISFACTORY', 2),
            ('03af5a3e-c0fa-586b-babe-6824a83ba257', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-A', 'Option A', 'DEFICIENT', 1),
            ('06544920-5733-5fdb-bd42-e7faefda2193', 'a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('07ae1a5a-ae0d-50cb-9ea5-717c013203c9', 'bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('083346ba-ff8f-5f2f-9697-6fc2ea6a8120', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-A', 'Option A', 'OPTIMAL', 1),
            ('08606590-d8cd-5f4f-8e98-645ac5d5fb08', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o3', 'Je choisis A : le projet bilingue représente un avantage éducatif important pour le développement de mon enfant.', 'PARTIAL', 3),
            ('08826d10-a690-524c-b849-a71d9419e8e2', 'f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('08bcd0f0-79d6-5d45-b013-259e82ba960b', '6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16-X', 'Option X', 'SATISFACTORY', 1),
            ('0a0262fb-2b3d-5c62-ac7b-c0b8484f0ee6', 'ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1-Y', 'Option Y', 'SATISFACTORY', 2),
            ('0a033855-7831-505d-bae7-b5dfc85af7de', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-C', 'Option C', 'OPTIMAL', 3),
            ('0a0cc54f-049f-53c0-8650-f6cd1dbfe467', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o1', 'Je choisis A : il respecte le plafond de loyer et le trajet de 25 minutes reste dans la limite. B dépasse le trajet autorisé, C dépasse le budget. Le calme du quartier est un plus mais ne peut pas primer sur les contraintes obligatoires.', 'OPTIMAL', 1),
            ('0a4a97bf-5638-5483-8d40-e2394955e886', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('0a5f1d17-2926-50bf-9ac4-7f44007914e1', 'fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('0aa710a6-7401-58bc-be38-9bf540fade30', '48c98228-9651-52c0-b294-373733227320', 'RE-6-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('0b65377b-1c24-516b-8cb7-b7f29f441cfc', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o4', 'Je choisis C car un traiteur gastronomique valorise l''image de l''entreprise.', 'DEFICIENT', 4),
            ('0b84d280-1aa2-562b-bb3c-251b6fb43c3a', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o1', 'Je choisis A : le tarif respecte mon budget et le véhicule est compatible avec mon permis B, contrairement à B (permis non détenu) et C (hors budget).', 'OPTIMAL', 1),
            ('0bc0ea9a-6273-50c2-a7c5-4b928860da29', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o4', 'Je choisis B car les avis en ligne sont nombreux.', 'DEFICIENT', 4),
            ('0c000d3a-d6bf-5180-9e31-53b28ebfa890', '037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15-X', 'Option X', 'SATISFACTORY', 1),
            ('0d9201b2-d165-5831-94a6-770dfa1ce55b', '554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('0eaae52b-829d-55db-a239-81b3cdb364d4', '7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13-Y', 'Option Y', 'SATISFACTORY', 2),
            ('0efff163-0077-534b-bd36-67d45bca5fa6', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o3', 'Choix de X sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('10bccf4f-d85a-53af-91cb-1fbb05d9d6ed', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-B', 'Option B', 'DEFICIENT', 2),
            ('1182a920-9fb3-5454-8cd6-402e2d29c728', '6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17-Y', 'Option Y', 'SATISFACTORY', 2),
            ('1191f1d0-a0d8-5fb5-a2ae-f7a93a81d395', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o2', 'Choix de Y avec justification partielle cohérente.', 'SATISFACTORY', 2),
            ('12af20ac-ddc5-5233-ba2e-bb862836a120', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-C', 'Option C', 'OPTIMAL', 3),
            ('16873c44-9d0e-5301-8e33-e9ccdf2fc872', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o3', 'Choix de Y sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('1761d9fd-c353-5fc6-9343-6782b1240429', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-A', 'Option A', 'DEFICIENT', 1),
            ('1894dae4-b255-53c9-9c9a-aa537b85d2de', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o2', 'Je choisis A car le véhicule me semble facile à conduire.', 'SATISFACTORY', 2),
            ('18cb2179-8340-5610-91b9-c31258e7206d', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-B', 'Option B', 'DEFICIENT', 2),
            ('1923e7be-27d6-5bec-b5d2-050c67ff56a5', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o1', 'Je choisis B : le tarif respecte mon budget et le format soirée est compatible avec mon emploi du temps. A est éliminé par son format journée incompatible. C est hors budget. La reconnaissance internationale de C est attrayante mais sans rapport avec mon usage prévu.', 'OPTIMAL', 1),
            ('1adecb50-0d38-5fc0-9024-d2425d4c9878', 'e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11-X', 'Option X', 'SATISFACTORY', 1),
            ('1b4cbf12-7687-50a4-891d-bda48cced079', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o2', 'Je choisis B car il a de bonnes notes et un trajet acceptable.', 'SATISFACTORY', 2),
            ('1b9db7ff-eaec-5afb-a593-2e4fd6cd28a6', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-B', 'Option B', 'DEFICIENT', 2),
            ('1bd4f824-5a28-5d9f-b3df-934b637a55aa', 'fe062399-6f51-56c9-9872-a728907eb32f', 'RE-8-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('1c049bfc-1e11-5304-8590-03fb463e0c12', 'e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14-X', 'Option X', 'SATISFACTORY', 1),
            ('1c2135a8-8065-5266-8121-caaaebf9633b', '7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('1c927f47-d896-5c61-9dc1-e4b835aadb2b', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o3', 'Je choisis C car la note excellente suggère un meilleur confort pour un déplacement professionnel.', 'PARTIAL', 3),
            ('1e33e9a3-d34f-58e2-b6f0-2e3470101b24', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o3', 'Je choisis C car une meilleure autonomie réduit le risque de panne lors d''un déplacement important.', 'PARTIAL', 3),
            ('1ef9eea3-ab12-5434-b610-7527dee660ee', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-B', 'Option B', 'OPTIMAL', 2),
            ('1f9283e7-ba48-5dff-b5e6-8a27929a3021', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o4', 'Je choisis A car l''interface graphique est plus intuitive selon les démos en ligne.', 'DEFICIENT', 4),
            ('20a2cc01-f908-505f-ad45-c76f5be491bb', '1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('231cfd22-6099-55dc-b415-e1d9aecb63ad', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o2', 'Je choisis C car il est pleinement compatible avec notre environnement actuel.', 'SATISFACTORY', 2),
            ('263b1f22-d437-5080-834c-5a76d446f9a5', 'e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('26832cf9-d59f-596e-b6db-13c919cbef5e', '524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4-Y', 'Option Y', 'SATISFACTORY', 2),
            ('2751ac1e-76b9-563d-ab98-c83a10bce056', 'e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('2905f646-80a2-5935-a181-dfc52c0dd617', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o4', 'Je choisis A car les locaux ont l''air spacieux sur les photos.', 'DEFICIENT', 4),
            ('29650e78-205a-5530-b2b6-298cb72574b7', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-C', 'Option C', 'DEFICIENT', 3),
            ('2b06ece1-d056-5781-a342-a33ab9409a33', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o4', 'Je choisis B car le site internet est plus clair et facile à utiliser.', 'DEFICIENT', 4),
            ('2c0db527-b5f9-5889-967b-3957870f6b56', '1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('2d70e3b2-eb12-5875-8ca5-1be5cab57384', '554522ba-b497-5280-8eaf-a862a0e06c3d', 'CS-12a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('2db30a44-380b-54ae-b8ab-8997c09e573a', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o1', 'Choix de Y — maximise l''utilité espérée (140 € > 120 €).', 'OPTIMAL', 1),
            ('2e355635-277a-5522-bf87-bf1036e63ec2', '4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('2edf257e-dffc-5191-b6a1-bd33c09930f0', '554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5-Y', 'Option Y', 'SATISFACTORY', 2),
            ('31291669-0bd8-5dcc-8eb4-6e5834d27c44', 'b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('31cd67ba-ae8b-5e0a-b20b-a74e95890955', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-A', 'Option A', 'OPTIMAL', 1),
            ('33379b5b-b4e4-5931-904e-3eae17218125', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o3', 'Choix de Y sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('33a961c2-66f5-59e5-a6d6-127366ad86d5', '908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('33ab888b-885d-5fc9-8e8f-2fa6052d8500', 'ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3-Y', 'Option Y', 'SATISFACTORY', 2),
            ('3428532d-0c20-5419-a088-06d7276df872', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o4', 'Je choisis B car la façade est plus esthétique.', 'DEFICIENT', 4),
            ('35ab8e10-534d-5191-8b1f-56bf5095764d', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o1', 'Je choisis B : il respecte mon plafond budgétaire et son trajet de 8 minutes reste sous les 10 minutes requises. C est hors budget et A est trop éloigné.', 'OPTIMAL', 1),
            ('367ecf99-a552-552f-89af-d7a461f08538', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-B', 'Option B', 'DEFICIENT', 2),
            ('36b4d4e1-19e5-587a-bfb7-35e5e389222f', '2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('372ac519-4e77-580a-977c-6fb04c1b10e4', 'b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10-X', 'Option X', 'SATISFACTORY', 1),
            ('37f85506-7924-57a0-b429-c8c53e32dcdb', '91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('39066a0c-59f7-524b-abb5-bbfd5b5bfd54', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-A', 'Option A', 'DEFICIENT', 1),
            ('39105868-cfc7-52a7-82da-1ae27f2c59be', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-C', 'Option C', 'DEFICIENT', 3),
            ('3983c9ee-e927-53a5-988a-51044e6feb51', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o1', 'Je choisis C : le tarif est dans le budget et le délai de 6 jours respecte l''exigence contractuelle de 7 jours. A dépasse le délai (18 j), B dépasse le budget. L''absence de certification ISO de C est un point de vigilance à surveiller lors du renouvellement.', 'OPTIMAL', 1),
            ('39ae53dc-dd22-5573-888d-6a7d5923e906', '6f79b3e0-8a43-54e3-92e6-8dd8fa39ab06', 'ER-17-X', 'Option X', 'SATISFACTORY', 1),
            ('3bd3286d-79c2-5cb4-9977-365f65bc205b', 'c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('3bd3e82b-ba65-503d-a3df-110e14d45dab', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o1', 'Je choisis C : le tarif respecte mon budget et un vétérinaire est sur place pour le traitement de mon chien, contrairement à A (pas de vétérinaire) et B (hors budget).', 'OPTIMAL', 1),
            ('3c3abbd8-53a7-59d4-9c79-8a685bb490cd', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o2', 'Je choisis B car les menus sont adaptés aux contraintes alimentaires de nos invités.', 'SATISFACTORY', 2),
            ('3d43391a-7783-53e2-823f-fb6a726ac085', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-A', 'Option A', 'DEFICIENT', 1),
            ('3da0adfa-c4ab-5684-a795-bc9381fa0309', '1a211490-500d-56fb-9e67-f6ad538d8c7c', 'CS-8a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('3de78682-725a-5058-ac1b-0fed16e5f219', '7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7-Y', 'Option Y', 'SATISFACTORY', 2),
            ('3e0db0bb-42d4-5a36-a698-a7a98aca72a4', '9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('3e6fe870-4936-50fc-a352-f9b889a562bd', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-B', 'Option B', 'DEFICIENT', 2),
            ('3eb39254-e146-5e28-8094-ca78d62bf14a', '61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18-X', 'Option X', 'SATISFACTORY', 1),
            ('3feeb88d-49d4-58a1-8af2-609ee141eb5d', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o2', 'Je choisis B car les performances couvrent les besoins professionnels du graphiste.', 'SATISFACTORY', 2),
            ('4173d1fe-2fdb-5a73-8437-a92209d77179', 'a9ad81c0-6e41-5e52-8c86-77390928099e', 'RE-22-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('418b0e1a-b7eb-5842-9886-5af150561382', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o2', 'Je choisis B car le débit est suffisant pour mes usages professionnels.', 'SATISFACTORY', 2),
            ('41db11e0-8ee9-5e9c-a863-5c0fcc129edf', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-C', 'Option C', 'OPTIMAL', 3),
            ('4244df0c-e4b7-59b2-ab33-0c4a68e6c603', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('4289298e-c1c2-5971-8f78-008f866f3cc4', '3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('43d9710f-9046-58f0-a63d-b97e2c04b4d4', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o3', 'Je choisis B : la faible consommation compensera le coût sur la durée, même si l''autonomie est limite.', 'PARTIAL', 3),
            ('44ed6059-aea7-54c5-8ed2-4c5bc12adbe7', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-C', 'Option C', 'DEFICIENT', 3),
            ('462c1eb4-96ec-5b5c-aad5-e5dcfd0018f9', 'e72b2661-3db2-58e5-b01f-cfc392e8e824', 'ER-11-Y', 'Option Y', 'SATISFACTORY', 2),
            ('47240920-2d56-5eff-8b67-ec1a7b950d8b', '75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('4841ab08-96c0-523d-9361-920074c99989', 'b3d4c0c9-3bf2-5a04-8a55-bcefbdfa33f1', 'RE-18-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('48d6f8b2-9a09-5112-9dbd-25abd1ad6bc1', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('48f6a541-24ab-5608-9d0f-4e86e5ef023d', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('494d9c0d-78ed-576e-94be-08d904dafdad', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o4', 'Je choisis C car le site du fournisseur est plus moderne.', 'DEFICIENT', 4),
            ('4971e0b8-44b1-52ac-a42a-caefce214285', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o1', 'Je choisis B : le tarif est dans le budget et les spécifications (16 Go RAM, GPU 4 Go) sont suffisantes pour les logiciels de retouche et montage utilisés. A est éliminé par des performances insuffisantes pour le montage 4K, C par le dépassement budgétaire.', 'OPTIMAL', 1),
            ('4a6ff0fd-9473-5698-818d-7d0266ca1837', '07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('4afa7948-4932-5514-9c8b-7dae2890d65c', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-A', 'Option A', 'OPTIMAL', 1),
            ('4b92fa91-b7b1-54c8-832f-4dd477cffabb', '908c3cc6-25cd-5011-854d-a7501d96a6b2', 'CS-12b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('4c3dcb53-421c-5c62-9b5e-2c65f0e97acc', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-A', 'Option A', 'OPTIMAL', 1),
            ('4c9813c3-01fe-5d36-a41e-6bc059ebcb26', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o4', 'Je choisis B car l''ambiance de la salle m''a semblé meilleure lors de ma visite.', 'DEFICIENT', 4),
            ('4e4fa165-f5da-5665-9418-95c0abae0c30', '9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('4eab7035-99a4-5e26-a3eb-117fb8315fa4', 'e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6-Y', 'Option Y', 'SATISFACTORY', 2),
            ('50139aef-37b5-5acd-b25d-54a98e65406a', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o1', 'Je choisis B : le tarif respecte le budget et les menus couvrent les deux régimes identifiés (sans gluten et végétarien). A ne propose aucune adaptation, C dépasse le budget.', 'OPTIMAL', 1),
            ('518de00e-c847-5fe4-8983-07dce930c00f', 'e412ab19-790b-5db3-bdd6-dc53ba3d267a', 'CS-11a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('51a91f9a-ad1f-5b8c-99c7-2897d3e295f8', 'f3fe59e9-79d0-554a-9b5f-7795fe3ba3fc', 'RE-11-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('51e6f000-e5db-5cc1-93d1-ce17a172a79a', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o1', 'Je choisis A : le tarif respecte le budget et l''assurance couvre intégralement la valeur de mes biens. B sous-assure (50%), ce qui représente un risque financier direct. C est hors budget.', 'OPTIMAL', 1),
            ('537c7599-20d6-5368-9b7d-eba699714476', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o2', 'Je choisis C car c''est un CDI avec des perspectives d''évolution intéressantes.', 'SATISFACTORY', 2),
            ('53d2190c-7352-5df6-b8bc-fb4e73fe2637', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o3', 'Je choisis B car le trajet de 50 min est long mais le loyer bas me permet d''économiser et le quartier calme est important pour moi.', 'PARTIAL', 3),
            ('53d363a6-12c7-57a3-a00d-61eb045d66cc', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-A', 'Option A', 'DEFICIENT', 1),
            ('53d6b7a9-cc8f-5e62-8d58-9baedfab51f3', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o3', 'Choix de X sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('53d92898-ae83-5289-99d6-975b45032258', '5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('541ce987-a317-551a-a09c-8176fb33dcc8', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-B', 'Option B', 'DEFICIENT', 2),
            ('54d34544-e6b6-5577-9b06-6c619d5b30ac', '68173ddd-63fd-5019-a6db-409620345268', 'RE-14-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('55b6d53a-789a-5230-83bb-d4a881ba44a6', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-C', 'Option C', 'OPTIMAL', 3),
            ('5676ed1d-ec54-5b87-8de3-43aa98597032', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-C', 'Option C', 'OPTIMAL', 3),
            ('59ffcf8b-c390-560b-85f6-233655430167', 'abbf0b0c-960b-5da0-b16f-68001f1c8f2a', 'DT-13-C', 'Option C', 'DEFICIENT', 3),
            ('5b14bb6b-75ab-5595-96d5-c139933281b8', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('5c10b247-98e1-526f-950a-00d2c30d77b8', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o4', 'Je choisis C car les camions neufs indiquent une entreprise sérieuse.', 'DEFICIENT', 4),
            ('5c87ad07-91fa-5876-bec6-58b8f2ef0e41', 'da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('5cb1afb9-04d1-55f8-aad8-20a81f5a9e83', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-B', 'Option B', 'OPTIMAL', 2),
            ('5d9e65b0-19df-5e91-9f7a-aeeb72dd90ec', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('5f512df0-ffee-5327-80af-aee4e089151f', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o2', 'Je choisis C car le délai et le prix correspondent aux exigences du contrat.', 'SATISFACTORY', 2),
            ('5f51bfaa-0b0d-5b7b-a8f3-22d474c8ff41', '8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('5fcdcde9-2d48-59fe-8de4-e9f5b96f275d', '308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('5ffecfc2-4610-5289-ae51-8f23fd62f6b3', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o4', 'Je choisis B car un fournisseur cher inspire plus confiance pour un contrat stratégique.', 'DEFICIENT', 4),
            ('603bf571-7b73-569c-baf8-8b76840fdc94', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o1', 'Je choisis C : le tarif est dans le budget et les 4h de salle incluses par semaine couvrent nos besoins habituels. A ne propose aucune salle privée, B dépasse le budget.', 'OPTIMAL', 1),
            ('6119ce91-2453-5796-bec2-9a70e170970f', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o4', 'Je choisis A car la décoration est plus moderne et l''ambiance propice à la créativité.', 'DEFICIENT', 4),
            ('61894c1e-a34b-5220-a563-45e6f1b801ac', 'b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('61b3bc8e-2c1b-5d62-8d31-245427b2960e', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o1', 'Choix de Y — maximise l''utilité espérée (50 € > 45 €).', 'OPTIMAL', 1),
            ('624b3a31-1860-5cca-9063-c2c54f6cf6ab', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-B', 'Option B', 'DEFICIENT', 2),
            ('654fd005-ff61-571f-ba8a-8068777043ab', '71b34741-0338-5fb6-aade-816894f23a66', 'DT-11-B', 'Option B', 'DEFICIENT', 2),
            ('660dbefc-5d38-5b5a-aaea-2d552cdfaadc', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-C', 'Option C', 'DEFICIENT', 3),
            ('67fbed93-f333-59f6-b1e6-f31e50b92e3a', '3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2-Y', 'Option Y', 'SATISFACTORY', 2),
            ('684e4c18-1d4e-5b5b-baeb-3aa35f96fe09', 'f437d62d-1cf9-5d54-97bd-490dec3a2d2b', 'II-16-o3', 'Je choisis A : les invités avec allergies peuvent apporter leur propre repas, ce qui est courant dans ce type d''événement.', 'PARTIAL', 3),
            ('68e06f9b-54ca-592c-a31f-16889905ab05', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o2', 'Je choisis A car l''autonomie suffit pour mes besoins professionnels.', 'SATISFACTORY', 2),
            ('69207ac6-a7b4-51c9-b63c-52f7b7dcc88c', '1b44a5d0-7134-53f6-93e7-94d7ed5c3e1f', 'CS-11b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('6924357b-aa26-54a1-a698-bad20e4d7095', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o1', 'Choix de X — minimise la perte espérée (−60 € > −70 €).', 'OPTIMAL', 1),
            ('6a2144aa-e9ba-57e3-ae89-60bf8c293d3f', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o2', 'Je choisis A car le loyer et le trajet me conviennent, et le quartier calme est appréciable.', 'SATISFACTORY', 2),
            ('6a743dca-19b2-5b68-904e-236a7fddf810', 'a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('6c078040-9aff-599f-b003-10f41ad6f6e6', '11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('6c87c23a-730e-5390-96db-b4b6f451b3a7', '07c789db-fe72-58e2-a180-b8e584dbdfbd', 'CS-10b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('6c9fa250-6897-5ee6-8bc3-c340c9cece71', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o1', 'Je choisis C : l''abonnement respecte mon budget et la salle est à 12 minutes, soit sous les 15 minutes requises. A est trop loin (40 min), B dépasse le budget.', 'OPTIMAL', 1),
            ('6ce422d3-6ca9-5b9b-8165-2b10faf53dc0', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('6e1aea34-ac75-5990-8612-88bc53b1460d', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o2', 'Je choisis A car l''autonomie me semble suffisante pour mes trajets.', 'SATISFACTORY', 2),
            ('6e2d8967-9254-50f2-ba92-9cbb26ff4f53', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-A', 'Option A', 'DEFICIENT', 1),
            ('6e49792c-2bb8-561b-a9ac-b9c59c1678b4', 'ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('6e86d14b-c425-57af-ad5b-1862588a29b0', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('6e8963c0-7de4-57ff-ae60-2afab5c1d068', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o3', 'Je choisis C car un avocat plus cher gagne toujours plus de dossiers.', 'PARTIAL', 3),
            ('6eb85c4d-2900-54a0-a8b3-e13ac37162bc', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o1', 'Je choisis A : le loyer respecte mon budget et l''accès PMR conforme répond à mon obligation réglementaire, contrairement à B (non accessible) et C (hors budget).', 'OPTIMAL', 1),
            ('6fdb5d10-462e-5785-82f8-fadb260640fb', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o1', 'Je choisis C : la licence respecte le budget et l''intégration couvre la messagerie et le CRM, ce qui est la condition posée. A est incompatible, B n''assure qu''une compatibilité partielle.', 'OPTIMAL', 1),
            ('7084ac9a-1f1a-52d7-b3ef-be4610020046', '9005bc10-455e-5de5-87d9-5684042440e2', 'RE-5-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('710ddbe6-6aac-5c8d-9c00-00680fe384c1', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-B', 'Option B', 'OPTIMAL', 2),
            ('71743d18-3021-58b0-8fcb-362c744dae43', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 'DT-9-A', 'Option A', 'DEFICIENT', 1),
            ('71abe258-c7d7-57ca-843f-283e28dca9eb', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o4', 'Je choisis A car cet opérateur est celui que j''ai toujours utilisé.', 'DEFICIENT', 4),
            ('722c38e6-b518-5872-a3cd-f9928a57c545', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o3', 'Je choisis C car un camion plus cher est toujours plus fiable.', 'PARTIAL', 3),
            ('75d2078b-7d7d-5e76-b28e-f90cbc1b701e', '037fdfd4-d2da-58be-a99b-7f917a9829c7', 'ER-15-Y', 'Option Y', 'SATISFACTORY', 2),
            ('763bd3d3-418a-5c64-a107-d04abef2522c', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o3', 'Je choisis C car un local plus cher est toujours mieux situé.', 'PARTIAL', 3),
            ('76747195-0a06-5945-9dea-b1f59957e1ae', 'e330f06f-8460-5b9f-a83c-60f81a877995', 'ER-14-Y', 'Option Y', 'SATISFACTORY', 2),
            ('78256fac-a63c-5739-b7f7-a2eaf98959fb', 'e1497d9c-2918-55be-9da7-782be7e3ccad', 'ER-6-X', 'Option X', 'SATISFACTORY', 1),
            ('78b0226c-46e7-538a-876c-9051f23117d6', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o3', 'Je choisis B : le salaire supérieur me permet d''épargner et 18 mois c''est suffisant pour me retourner.', 'PARTIAL', 3),
            ('7d35b6b5-9c88-5613-a16f-10ced83d892e', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-B', 'Option B', 'DEFICIENT', 2),
            ('7e1872c8-ae6d-58af-903d-1829d00da945', '8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('7ed4c7fd-827e-5f9e-852d-d2a2f9519def', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-C', 'Option C', 'DEFICIENT', 3),
            ('7fe44315-2d5a-5f85-9a1a-b1249a62558e', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-A', 'Option A', 'DEFICIENT', 1),
            ('801790df-0ac3-57c2-8556-2c4cea1e7fe2', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 'II-3-o4', 'Je choisis C car un trajet court est plus important que tout le reste.', 'DEFICIENT', 4),
            ('802c09ec-bd66-5b79-ac06-3bb6d5f38c38', 'b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('8056a568-990a-53a4-9c0a-88f20a9b8dc9', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o2', 'Je choisis C car l''ambiance calme est essentielle et le prix reste acceptable.', 'SATISFACTORY', 2),
            ('816ff20d-a39b-554f-bb3a-2efe32f1027d', 'a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('82e6d8a1-3245-5128-aa7a-0e05f9f6709d', 'b32ea892-abfe-58be-80f6-a747c4a7eaad', 'DT-5-B', 'Option B', 'DEFICIENT', 2),
            ('859aee84-b482-57f6-8b71-9bc82c3ecf9a', '8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('8751130b-bb14-5948-967d-cef2a4076317', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-C', 'Option C', 'DEFICIENT', 3),
            ('877133d2-f033-56ad-a772-8a26dcd72721', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o2', 'Je choisis C car un vétérinaire est présent.', 'SATISFACTORY', 2),
            ('879b88ca-9b4c-5f06-a466-aba9770563a6', '8381149d-7bef-516b-9a2f-a041d066efe3', 'RE-17-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('88080917-a8e0-5be1-a4fa-fac070cfce99', '7df66852-2433-5e90-a49f-95563e16e090', 'CS-6b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('88817352-6f44-55de-a7e1-a14533e52ee1', 'bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8-X', 'Option X', 'SATISFACTORY', 1),
            ('88d1ac4b-eb19-5fc0-b5d1-b41ad9569628', 'b7eb6493-475b-5448-a727-443321d60f34', 'CS-5b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('89ad09d3-64cc-5a89-b8e2-ebeecb9ad896', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o2', 'Je choisis C car la distance et le tarif me conviennent malgré des équipements légèrement moins récents.', 'SATISFACTORY', 2),
            ('8a7faf14-d0cf-53fa-a2b5-2483308face9', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o4', 'Je choisis B car la proximité des transports en commun est importante pour l''accessibilité.', 'DEFICIENT', 4),
            ('8b6df7db-cd3e-5be0-96f0-825181a12ab8', 'e83908d6-061a-5d74-8a41-18068fdc5e92', 'CS-7b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('8c0c7b42-dea9-5f6e-8696-98af4a95906d', '7c466c90-4e14-5018-b1a8-c8bc55eab553', 'ER-13-X', 'Option X', 'SATISFACTORY', 1),
            ('8c27ac7a-f36b-5f4e-b6d6-d1a545019580', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o2', 'Je choisis C car l''antécédent est couvert et le tarif est acceptable.', 'SATISFACTORY', 2),
            ('8d91f023-d81d-5a2b-926f-b1c3227ed80d', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('8d9b9a78-409b-5047-9866-a53792610f78', '524daffc-8e33-5462-81eb-5ac89fc0d82b', 'ER-4-X', 'Option X', 'SATISFACTORY', 1),
            ('8daf66ac-d9d4-59d5-b103-2a26bdf87d6a', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o1', 'Je choisis B : le tarif est dans le budget et les horaires 7h30–19h couvrent mon amplitude 8h–18h30. A est éliminé par ses horaires trop courts, C par son tarif hors budget. Le projet bilingue de A et C est intéressant mais ne peut pas primer sur les contraintes pratiques.', 'OPTIMAL', 1),
            ('8dda646e-b83a-5eaa-9541-147406599661', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o1', 'Je choisis A : il respecte mon budget et son autonomie de 550 km couvre largement mes trajets de 250 km. B est éliminé par une autonomie trop faible (280 km < 500 km), C par le dépassement budgétaire.', 'OPTIMAL', 1),
            ('8ebea235-e2df-5e90-afdd-debf1b900c3a', '91301756-fed8-535f-807f-d36e41a520f7', 'CS-3b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('8f804d44-c4fb-5277-bcd7-cb379ed5b694', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o2', 'Je choisis A car l''équipe me semble compétente.', 'SATISFACTORY', 2),
            ('91c9cf84-2d01-5cb9-aba9-e7b432eb2397', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-A', 'Option A', 'OPTIMAL', 1),
            ('9367a23c-d956-5c26-bee4-a474c5c6111d', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-A', 'Option A', 'DEFICIENT', 1),
            ('93a71db4-8627-517b-bba1-46d69edc1a63', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-A', 'Option A', 'OPTIMAL', 1),
            ('94f937e5-7909-5680-85a3-c810be940bb1', 'a47cc647-9776-5488-81ca-3dd5c43f138c', 'DT-16-A', 'Option A', 'DEFICIENT', 1),
            ('97c74975-9f75-5930-a7cc-57157d067b96', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('99a64320-8dcb-52d9-8d2e-92095507575c', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o4', 'Réponse incohérente ou absente.', 'DEFICIENT', 4),
            ('99c1d13c-1f6b-5bdd-a949-f5b9697e1711', '364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('9b558939-a41f-5778-9e85-8f4ed2e02060', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-B', 'Option B', 'OPTIMAL', 2),
            ('9b5d8d55-6d73-5be8-8deb-2cfeb5e64b84', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o1', 'Je choisis A : le tarif respecte mon budget et l''équipe est habilitée travail en hauteur, comme l''exige la réglementation, contrairement à B (non habilitée) et C (hors budget).', 'OPTIMAL', 1),
            ('9c5687d9-a2e3-5a59-85da-526e1895f974', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o2', 'Je choisis A car la capacité est suffisante et le budget est respecté.', 'SATISFACTORY', 2),
            ('9cc0da5d-555e-54e0-854d-7bdff7c58ec2', '2a108c71-8ae8-5409-a136-c57fd38752cb', 'CS-1b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('9dae2b7c-464c-54e9-9a12-a772fedb7ca8', '02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('9e22253c-fbdf-5b70-a232-8734139ab802', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o4', 'Je choisis A car le nom de l''organisme de formation m''est familier.', 'DEFICIENT', 4),
            ('9ea47f1a-4873-5e40-b469-fa04e549d1d3', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 'CS-3a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('9ed5117a-55db-501e-af98-e6be77e48571', '3a67700c-d87c-5b28-b818-1fada3f8de3c', 'RE-21-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('a03e6e0f-906d-5bfc-b739-5775738e5807', '6ecde917-88e3-5b1c-86ec-f69d7cf99b74', 'II-9-o3', 'Je choisis A : les équipements récents valent le trajet plus long, surtout si j''y vais en vélo.', 'PARTIAL', 3),
            ('a1e1db60-676d-5b8c-9bb1-a2f8041e4f42', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o4', 'Je choisis B car les critiques positives me rassurent sur la fiabilité.', 'DEFICIENT', 4),
            ('a22c04f0-71f5-5071-a9bd-b4a49e962cbe', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o3', 'Je choisis B car un fournisseur plus cher est toujours plus fiable.', 'PARTIAL', 3),
            ('a3be7c88-6329-5e7b-a7ae-034a5fde2f5d', '27c61c28-e242-5e00-ac72-8cb4b1237077', 'II-21-o3', 'Je choisis B car une pension plus chère est toujours plus sérieuse.', 'PARTIAL', 3),
            ('a3ca85ea-7683-5813-a89d-c48bbb13fdba', '3342ece6-a51c-5494-bf60-67904ee35695', 'ER-2-X', 'Option X', 'SATISFACTORY', 1),
            ('a410f0ce-5886-5754-9def-2c61c0512ed5', 'bc40741e-a96e-5bfa-80c5-c331379db9e0', 'RE-23-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('a473f9a9-81b3-5fcb-9a99-1d6c7fdcc78b', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-C', 'Option C', 'DEFICIENT', 3),
            ('a4c31a04-a97c-5a22-b87c-8f1b544fa1f9', '7b6a2679-ebf0-546a-a986-b5fa6b705661', 'DT-20-C', 'Option C', 'DEFICIENT', 3),
            ('a75eae0d-9aac-5810-9b2e-5ddcc2c5c315', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o3', 'Je choisis C : investir dans la meilleure configuration réduit les risques de lenteur et prolonge la durée de vie utile de la machine.', 'PARTIAL', 3),
            ('a8b61728-39a7-58cf-931e-d4b2bbafcacc', 'a41e521f-cfda-5d32-9682-2a6363b5b469', 'DT-4-A', 'Option A', 'DEFICIENT', 1),
            ('a8ed3ff5-b99e-502c-a634-15069d2f31d9', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o2', 'Je choisis C car les salles de réunion sont disponibles et le tarif est acceptable.', 'SATISFACTORY', 2),
            ('aa65d1bd-253e-547d-bf85-0c110e9f4039', 'a360a15b-c014-5ee5-a205-55c4773d7742', 'DT-22-B', 'Option B', 'OPTIMAL', 2),
            ('aae89639-4b7f-5383-969b-a362294a47bf', '05d6d3de-fa35-5749-bc78-0d7aa5b875e5', 'DT-2-B', 'Option B', 'DEFICIENT', 2),
            ('ac56da70-6ea9-59cf-9858-f07aa8af5c6a', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-A', 'Option A', 'DEFICIENT', 1),
            ('adce558d-7e93-56c7-b005-bc51dd29e997', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 'CS-2b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('ade07f99-e388-5146-92b1-0a9c7cfbd55a', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o1', 'Choix de X — minimise la perte espérée (−250 € > −280 €).', 'OPTIMAL', 1),
            ('b019c34b-daa0-574a-b5d4-17000616430a', '0fdc563a-36a9-56d8-af59-11ef34cc8141', 'II-19-o2', 'Je choisis A car l''accessibilité me semble correcte.', 'SATISFACTORY', 2),
            ('b040c309-206f-558f-90fd-abd8f8b4a662', '02b12211-ba21-5404-a98c-f9cb6135ea6e', 'RE-15-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('b04d2fd2-7103-5d5e-9032-ba2de9619fac', '38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('b0b53e4a-c407-55cd-b2a7-36f47bfbd561', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o4', 'Je choisis B car le cabinet est plus proche de mon domicile.', 'DEFICIENT', 4),
            ('b1ca8f7c-61bc-50a3-90a4-33856bece3b2', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-C', 'Option C', 'OPTIMAL', 3),
            ('b3bfe50f-4b7b-53ce-9012-aabf539c18f6', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o3', 'Je choisis A : une couverture complète vaut l''investissement supplémentaire, surtout avec un antécédent.', 'PARTIAL', 3),
            ('b3c17631-96fc-531a-8c11-f749b41681c0', 'da65f0ab-0192-5966-96f8-89760721fafb', 'CS-9b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('b43390cd-6249-553b-bd16-b4d2da532cfd', 'ec502e25-2d2a-5f62-9a76-bda9ec9d327f', 'DT-24-C', 'Option C', 'OPTIMAL', 3),
            ('b459d7fe-c19f-5a86-9461-f7978c418e15', '8c95bbdf-0774-5bd2-9453-7e82eaefb539', 'CS-8b-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('b5b62fdf-5555-50d2-a42e-4a1b3d2df97f', 'b4fb84bf-ab5e-5675-b740-9c9407aeb60d', 'RE-16-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('b644ce0e-25aa-59e4-b73d-97e7028c2d42', '7acffa93-ca82-5b53-ad85-3cee9bccf793', 'ER-7-X', 'Option X', 'SATISFACTORY', 1),
            ('b87dbe1a-8f18-505a-8cfe-5eea63e98782', 'b1dee2c5-6515-5384-b811-a7b6ae2e1ec4', 'ER-10-Y', 'Option Y', 'SATISFACTORY', 2),
            ('b87df35a-a073-54f4-92dc-12db4725a1a6', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o2', 'Choix de Y avec justification partielle cohérente.', 'SATISFACTORY', 2),
            ('b9c591a5-5d4c-5451-b717-c0d30d767f1f', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-C', 'Option C', 'OPTIMAL', 3),
            ('ba74622a-d004-5e6d-be7e-42e9715ac969', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o3', 'Je choisis C : la reconnaissance internationale est un investissement dans ma carrière à long terme.', 'PARTIAL', 3),
            ('bb19118d-b7c5-576f-ab16-e34d32b337e3', '9afb82a9-dc9c-5ebf-ae2a-69c632603a64', 'CS-5a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('bb6cd4ec-9899-571e-a55c-e45497af3067', '8224d1cf-b5ad-50c5-93a5-4ea9aa46273c', 'RE-7-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('bb974a08-dcc0-582b-9e39-7672310db14f', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o1', 'Je choisis C : il respecte le budget de l''entreprise et son ambiance calme permet de conduire la réunion. A est hors budget, B trop bruyant. La différence de note entre C (4.2) et B (4.5) est non significative face aux contraintes.', 'OPTIMAL', 1),
            ('bd6ed22c-709e-5992-9aef-68663bb9ad12', '72d0d8f8-1ae2-5bb9-b386-56e310bcfb2d', 'II-12-o2', 'Je choisis B car les horaires et le budget me conviennent.', 'SATISFACTORY', 2),
            ('bd8cb0af-1513-55be-9b39-dfb085b8720a', 'c5165793-f872-5631-a530-2aa0ce91adab', 'RE-4-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('bda60765-44e2-520a-9b9a-7562a9532532', 'a139e36e-407a-54af-a904-a0311a1c2318', 'RE-2-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('be39b96e-bce4-5fe5-b275-a634db1a8d0f', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 'RE-1-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('bef901f3-52ae-5c92-b066-8981127682d4', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o2', 'Choix de X avec justification partielle cohérente.', 'SATISFACTORY', 2),
            ('c00e1a6b-a4e4-51e5-9e8e-3595a6e2cfdb', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 'RE-3-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('c0a4181b-86a1-5a26-a1ee-5e02298c4609', '18b1f162-e573-561b-b7af-1d6ff1964865', 'DT-15-A', 'Option A', 'DEFICIENT', 1),
            ('c38df482-c5e0-5aac-b17e-059035c5a035', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 'II-2-o1', 'Je choisis A : son prix reste dans mon budget et son autonomie de 2 jours couvre mes déplacements. B est insuffisant en autonomie, C dépasse mon budget.', 'OPTIMAL', 1),
            ('c3b14eb9-4364-52c5-96a2-fcc4e3bb2015', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 'ER-24-o3', 'Choix de Y sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('c3e56a01-eba7-5122-ac23-b64e654350c2', '34e56502-0331-5190-a2d9-3dde31752808', 'II-10-o3', 'Je choisis B : la compatibilité messagerie couvre l''essentiel du travail collaboratif, le CRM peut être connecté manuellement.', 'PARTIAL', 3),
            ('c468c687-d176-540a-b422-74b634ad7c00', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-C', 'Option C', 'DEFICIENT', 3),
            ('c4f84528-739f-5218-a900-9033f3130e26', '4b90b69d-6e06-5805-b944-a238c0a70d41', 'CS-7a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('c60d5b38-9c8c-558f-848b-6275b2547118', '75a3c66f-a3f0-5bc4-ad13-7668c86c02e2', 'RE-10-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('c6e1582c-8c9f-524e-bb99-ee81fb45a076', 'bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('c812ba98-c273-5d22-a931-bd067c3ae44a', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-C', 'Option C', 'DEFICIENT', 3),
            ('c91cf9d8-f336-5cb1-8a13-91a16e562cc0', '64e15cd7-9efa-5cb4-ac47-fe2456455c1f', 'II-22-o1', 'Je choisis A : le tarif respecte mon budget et l''électricité est certifiée renouvelable, comme l''exige ma charte RSE, contrairement à B (hors budget) et C (non certifiée).', 'OPTIMAL', 1),
            ('c9fba659-3d94-50c3-acbd-5f62330972e7', 'c78fad0c-451f-5f06-a384-a61720b9a9b8', 'II-15-o3', 'Je choisis B : l''accès 24h/24 offre une flexibilité utile pour une équipe aux horaires variables.', 'PARTIAL', 3),
            ('ca9026b1-e8f3-56d5-9b21-647bc4998a40', '11c5c597-5e93-5a1b-aa14-805d47871e81', 'CS-1a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('caaa3147-7f4f-58e8-bc9a-f60aeeb64d28', '67432a01-21e8-594e-b5cc-5e34e156e24d', 'ER-23-o3', 'Choix de X sans justification ou avec justification incohérente.', 'PARTIAL', 3),
            ('cad19753-2e70-5248-8235-c7a0e24c41a5', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-A', 'Option A', 'DEFICIENT', 1),
            ('cc1f0fdc-3266-5dc1-bf5f-e41b957b839a', '61ce252a-9251-5ae9-98c0-cc4a3151fd8e', 'ER-18-Y', 'Option Y', 'SATISFACTORY', 2),
            ('cde6c180-5bbf-5b5a-bca1-f433c894ca9b', '5c5319ee-375b-56c7-a29c-4a3e41e4518a', 'CS-10a-A', 'Plan / Option A', 'SATISFACTORY', 1),
            ('ce46b51e-2bd8-5dcd-a66d-a7612cfcf7ef', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 'DT-8-C', 'Option C', 'DEFICIENT', 3),
            ('cf3a61a6-83d0-5520-8a2f-7607ad0d1269', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 'DT-12-A', 'Option A', 'DEFICIENT', 1),
            ('cfd61e25-3767-5c02-b7ed-b1a90eedf3d1', 'b87ab880-534e-55ad-922e-aa2216ab84b7', 'DT-3-B', 'Option B', 'DEFICIENT', 2),
            ('d209f792-363a-5651-850f-fac05211094b', '364f2ebb-c995-5375-90dd-1b7fafaf555a', 'CS-9a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('d2259ccc-c932-5a6c-99e6-6261a3ff1a6e', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o2', 'Je choisis B car les horaires et le tarif correspondent à mes besoins.', 'SATISFACTORY', 2),
            ('d256500b-65d3-5e75-942e-b344c2a13f4f', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o3', 'Je choisis B : disponible immédiatement et le surcoût d''assurance peut être souscrit séparément auprès de mon assureur.', 'PARTIAL', 3),
            ('d264a7b3-42e4-5508-b209-273b9962d642', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o2', 'Choix de X avec justification partielle cohérente (ex. aversion au risque explicitement déclarée).', 'SATISFACTORY', 2),
            ('d320c993-a67c-523d-ac22-21886aae08d0', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 'CS-2a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('d390fa52-067e-5363-95bc-9357e2c98b83', 'd2b2fcfc-9adb-579a-a120-d08a250e6fbe', 'DT-17-B', 'Option B', 'DEFICIENT', 2),
            ('d41e7e61-c43e-52c5-8c9e-abf835b9e9db', '6a1b1e21-ee17-554d-b132-5f78a723226e', 'ER-16-Y', 'Option Y', 'SATISFACTORY', 2),
            ('d4e866cd-59b2-548b-8213-716aec133042', 'bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('d5632baa-f9a5-5be9-8c01-d14126eb604a', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 'II-6-o1', 'Je choisis C : la prime respecte mon budget et la couverture inclut mon antécédent médical. A est hors budget, B ne couvre pas mon antécédent, ce qui représente un risque financier réel.', 'OPTIMAL', 1),
            ('d6816c16-4515-5c23-acea-1ccbed56ab67', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 'II-1-o4', 'Je choisis A car j''ai l''habitude de marcher et le prix bas m''arrange.', 'DEFICIENT', 4),
            ('d6ed004e-eb96-5a01-878e-8f7fd8ab9de9', '079e240a-dd17-59c1-ba0a-25b30d4187a6', 'DT-21-C', 'Option C', 'OPTIMAL', 3),
            ('d741b43c-83a9-5dd0-8394-4e4a7a1231a8', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o3', 'Je choisis A : la note excellente et le cadre professionnel justifient un dépassement de budget ponctuel.', 'PARTIAL', 3),
            ('d967ec9e-772d-5618-bb4a-ed25d13a5ef4', 'e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('d9a80853-8247-5a0d-8edd-c78cb1970d8d', 'bc8bb5f7-93d7-5679-8a99-5b62e33cb64b', 'CS-6a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('d9b36ac0-f0d4-57a0-9c2e-a3b4ee4a2e48', 'd7a1aaae-7c92-5fd7-962a-c49220775ed1', 'II-18-o4', 'Je choisis A car le design est plus léger, ce qui est pratique pour les déplacements.', 'DEFICIENT', 4),
            ('dac02a1a-74e6-5fcc-9b65-4e1d4105e618', '308b15c6-dc72-567d-91f9-f3a5ecbe33bb', 'CS-4b-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('dd3498a9-8b99-5ed0-b363-dd2bcbba5f82', 'bc0b4265-cc9f-50b0-b1e8-83dc142ab6f7', 'II-8-o4', 'Je choisis C car la décoration des locaux est plus moderne et rassurante.', 'DEFICIENT', 4),
            ('df069d76-ac01-548f-97a1-e970abbed0a2', '44e694aa-8313-5dd1-9015-8e81561ad03f', 'ER-20-o1', 'Choix de X — minimise la perte espérée (−40 € > −50 €).', 'OPTIMAL', 1),
            ('df440d38-9f99-5e87-89ab-c530a7bdc325', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 'DT-7-B', 'Option B', 'DEFICIENT', 2),
            ('e08c8ddd-7cd2-527c-a2c5-5c057ce272c7', 'dc5e2469-7e62-50b6-8b4e-c6e10450a5d5', 'II-20-o4', 'Je choisis B car la couleur du camion est plus discrète.', 'DEFICIENT', 4),
            ('e1552bc1-d6a6-5c8c-9cac-6682c855fcaa', '557c9f6b-5914-5beb-bffe-60715024d51a', 'ER-19-o1', 'Choix de Y — maximise l''utilité espérée (75 € > 60 €).', 'OPTIMAL', 1),
            ('e22c739d-7f7c-5a16-9888-19128a459078', '68173ddd-63fd-5019-a6db-409620345268', 'RE-14-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('e285fbe7-b66b-5258-936f-9fadb8723653', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-B', 'Option B', 'OPTIMAL', 2),
            ('e2d933a0-2ae8-5772-9d78-9e37f2a23ca7', 'e6ccd7ae-e78c-5828-9ed7-c71cf3213208', 'II-24-o3', 'Je choisis C car un prestataire plus cher est toujours plus sérieux.', 'PARTIAL', 3),
            ('e422509f-4c9f-5293-a339-64a6971cd083', '19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12-X', 'Option X', 'SATISFACTORY', 1),
            ('e44b24f6-1e43-576e-8642-12963ffa5474', 'fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('e5c582a8-46ad-5e85-ae5c-b1d0664fe956', '704f21f4-52ff-5482-9e03-976b7e581dcf', 'DT-23-B', 'Option B', 'DEFICIENT', 2),
            ('e6bd5d2f-2d32-5b78-8b70-88d85800c121', '8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9-X', 'Option X', 'SATISFACTORY', 1),
            ('e6f8588b-7021-5ce6-b13e-708796cca742', '0b849be2-47e2-5998-8cbc-bc4a8e8068f2', 'II-13-o2', 'Je choisis A car l''assurance est complète et le prix est acceptable.', 'SATISFACTORY', 2),
            ('e7270ba3-c6ff-5467-a252-b905fe228405', '58a504a1-4260-5f88-8ded-3f03907dc852', 'ER-21-o2', 'Choix de X avec justification partielle cohérente.', 'SATISFACTORY', 2),
            ('e7f0ed50-f91f-50bd-a1c4-f698e8f4fcea', 'ed4dbb61-a413-54f0-8149-e9ca47d5c51f', 'RE-13-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('e897530f-bde9-5bdb-a7d2-d76ea03b0b91', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o1', 'Je choisis A : les honoraires respectent mon budget et la spécialisation en droit commercial correspond à mon dossier, contrairement à B (non spécialisé) et C (hors budget).', 'OPTIMAL', 1),
            ('e90e3a5d-b4b2-59e7-ade1-c7caad6388c6', '6d7d9221-6439-5741-9d12-5c619dd687fe', 'DT-14-C', 'Option C', 'DEFICIENT', 3),
            ('e923b30b-ba69-53d7-b80d-96fafd2e466f', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-B', 'Option B', 'OPTIMAL', 2),
            ('ed5e2f52-f2ab-5515-953b-85fe73ae88ec', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o3', 'Je choisis C : la fibre optique 500 Mb/s garantit une stabilité supérieure lors des pics d''utilisation.', 'PARTIAL', 3),
            ('ed6fa99f-fea2-5dab-abc0-6d26740a9326', 'a8838481-597d-55bc-9f6a-423a73631bc3', 'DT-18-C', 'Option C', 'DEFICIENT', 3),
            ('ed8dfc2d-8a11-540f-bf40-9c262ef9c1b2', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-B', 'Option B', 'OPTIMAL', 2),
            ('edb3441c-fc4f-55c9-af1c-ab79644db95a', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o1', 'Je choisis A : le tarif est dans le budget et la salle peut accueillir 150 personnes, soit 10 de plus que les 140 prévus. B est éliminé par une capacité insuffisante (90 < 140), C par le dépassement budgétaire.', 'OPTIMAL', 1),
            ('edb50f43-e6e0-5194-a733-1a5e9d3b0a73', '63650717-5648-5191-91c5-244cbaa017f6', 'DT-10-B', 'Option B', 'DEFICIENT', 2),
            ('edecd206-60bc-5a5e-86bd-91cdc27d4c16', '554980dc-b8cf-50d8-a274-b07725b53565', 'ER-5-X', 'Option X', 'SATISFACTORY', 1),
            ('efdd9d4f-eee0-5cb1-b948-f496278a001a', '64b551c7-e5af-5465-ae08-c936819eb146', 'II-17-o3', 'Je choisis C : une salle plus grande offre une marge de sécurité utile si des invités de dernière minute se présentent.', 'PARTIAL', 3),
            ('f01adda8-912c-5fc5-b3f1-246047a5e084', 'bdda02bb-5815-516f-8dc6-b4b52643f89e', 'RE-19-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('f11fa9e4-7bfe-5dd6-a322-8568ba8c243e', 'ab17470b-a6d0-5bdb-bd94-f6f8aff8cddb', 'ER-3-X', 'Option X', 'SATISFACTORY', 1),
            ('f3836d38-5350-5bd9-99bc-798ff991fe7c', 'ca18f912-bdad-5b57-a67e-7b7fb299f12f', 'ER-1-X', 'Option X', 'SATISFACTORY', 1),
            ('f407578c-bc42-5e0a-a141-03f9dd12fd75', '48c98228-9651-52c0-b294-373733227320', 'RE-6-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('f459ad30-b378-5da4-849b-00d7be7dddd0', 'a1bbd2ab-37b0-5543-8ef9-3955475e35b4', 'RE-24-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('f5630837-f3a0-5788-8a88-c43c9a049c6a', '1783906b-d588-5575-b33d-a28b9b45ef45', 'DT-1-A', 'Option A', 'DEFICIENT', 1),
            ('f635d80f-4a7e-5074-8fba-e804b50f8dd5', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 'ER-22-o2', 'Choix de Y avec justification partielle cohérente.', 'SATISFACTORY', 2),
            ('f662e090-fcfc-59d3-9148-5bd991a29466', 'a33e0918-4b5b-564b-a165-ba34c7858724', 'II-23-o2', 'Je choisis A car l''avocat me semble compétent.', 'SATISFACTORY', 2),
            ('f781da2e-a290-55b8-99bd-2a396b8e7629', '881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('f841b42c-07c7-51c7-b51b-dca6a628597d', '87e601d9-7eb5-543a-a918-190e56ad20ca', 'II-4-o1', 'Je choisis C : c''est un CDI et le salaire atteint mon seuil minimum. A est éliminé par le salaire insuffisant, B par l''absence de stabilité contractuelle.', 'OPTIMAL', 1),
            ('f8b7583b-2ced-5b24-a526-5a1bffcb311b', 'fec252c6-ab6b-5563-b5e5-e0b087784119', 'RE-20-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('f958a36f-e695-540a-8b7c-f55dcfabc53e', 'e9d6ac7e-c979-52d8-8304-f094f0beb0c8', 'RE-12-DEFERRED', 'Option différée', 'SATISFACTORY', 2),
            ('f9a9a14c-b175-5c73-bbbc-c7b10d8d4a2d', '785021ff-1130-5225-ae9a-0290603803aa', 'DT-19-C', 'Option C', 'DEFICIENT', 3),
            ('f9b9ad30-d3b6-5886-b423-057f73ff6f3a', 'a5cdf0b0-13a1-5d8e-86c5-3702b5fd5aa7', 'II-14-o1', 'Je choisis B : le tarif est dans le budget et les 100 Mb/s couvrent largement les besoins en visioconférence et transferts. A est éliminé par un débit insuffisant (20 Mb/s < 50 Mb/s requis), C par le dépassement budgétaire.', 'OPTIMAL', 1),
            ('f9fdaeb2-20d3-584e-bb90-baf598a93596', 'bd937311-9098-59c9-83ac-61403aef0dd6', 'ER-8-Y', 'Option Y', 'SATISFACTORY', 2),
            ('fa02e736-a1ec-5792-bd11-34203a0d70f9', '8b9824a7-0247-5832-938b-114cf986ffd1', 'ER-9-Y', 'Option Y', 'SATISFACTORY', 2),
            ('fafc9728-55a9-5cc7-8957-c86e38d29102', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 'II-5-o4', 'Je choisis B car j''y connais le chef de salle et j''obtiendrai une bonne table.', 'DEFICIENT', 4),
            ('fc9d4d71-d1a5-5b62-8056-1cf774d9ee67', 'f612c942-3388-5e04-be17-7b8b6b2c3013', 'DT-6-A', 'Option A', 'DEFICIENT', 1),
            ('fcae1fb9-5f5c-5473-9b5a-b7dc2a997fc6', 'bfd90989-402b-59a4-b4d5-795ed7502790', 'II-11-o3', 'Je choisis A : la certification ISO 9001 garantit une qualité plus fiable sur la durée, même si le délai est plus long.', 'PARTIAL', 3),
            ('fd69efb8-ce71-508f-883c-79588db334d6', '881e903a-95ff-5961-a676-afa9b1715c09', 'RE-9-IMMEDIATE', 'Option immédiate', 'SATISFACTORY', 1),
            ('fd7f75e1-7518-5ed0-93dc-4fa770559a23', '38390bcf-c9a2-55bc-8550-b52eaccfcf2b', 'CS-4a-B', 'Plan / Option B', 'SATISFACTORY', 2),
            ('fddc741e-1c51-5e46-8050-fae4b36a05be', '19035253-ea98-5eb4-b7e3-3ba9c6a66a8c', 'ER-12-Y', 'Option Y', 'SATISFACTORY', 2),
            ('fff3c24a-8126-5593-a784-c3dc88c60f59', '4482c2f8-b059-5157-af35-803367bf1fb3', 'II-7-o4', 'Je choisis C car les commerciaux de ma connaissance préfèrent ce modèle.', 'DEFICIENT', 4);

        -- ── « Je Décide » — composition de la forme A (V67) : 30 lignes
        INSERT INTO games.decision_form_items (form_code, scenario_id, "position") VALUES
            ('A', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 15),
            ('A', '11c5c597-5e93-5a1b-aa14-805d47871e81', 19),
            ('A', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 25),
            ('A', '2a108c71-8ae8-5409-a136-c57fd38752cb', 20),
            ('A', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 3),
            ('A', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 2),
            ('A', '44e694aa-8313-5dd1-9015-8e81561ad03f', 8),
            ('A', '48c98228-9651-52c0-b294-373733227320', 30),
            ('A', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 27),
            ('A', '557c9f6b-5914-5beb-bffe-60715024d51a', 7),
            ('A', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 22),
            ('A', '58a504a1-4260-5f88-8ded-3f03907dc852', 9),
            ('A', '63650717-5648-5191-91c5-244cbaa017f6', 16),
            ('A', '67432a01-21e8-594e-b5cc-5e34e156e24d', 11),
            ('A', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 5),
            ('A', '71b34741-0338-5fb6-aade-816894f23a66', 17),
            ('A', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 13),
            ('A', '87e601d9-7eb5-543a-a918-190e56ad20ca', 4),
            ('A', '9005bc10-455e-5de5-87d9-5684042440e2', 29),
            ('A', '91301756-fed8-535f-807f-d36e41a520f7', 24),
            ('A', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 14),
            ('A', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 6),
            ('A', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 18),
            ('A', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 12),
            ('A', 'a139e36e-407a-54af-a904-a0311a1c2318', 26),
            ('A', 'c5165793-f872-5631-a530-2aa0ce91adab', 28),
            ('A', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 1),
            ('A', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 21),
            ('A', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 10),
            ('A', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 23);

        -- ── Emotional Radar — nuances par émotion (V50) : 30 lignes
        INSERT INTO games.emotional_radar_nuances (emotion, nuance_key, label, display_order, source) VALUES
            ('ANGER', 'FRUSTRATION', 'Frustration', 2, 'PROVISIONAL'),
            ('ANGER', 'INDIGNATION', 'Indignation', 3, 'PROVISIONAL'),
            ('ANGER', 'IRRITATION', 'Irritation', 1, 'PROVISIONAL'),
            ('ANGER', 'RAGE', 'Rage', 5, 'PROVISIONAL'),
            ('ANGER', 'RESENTMENT', 'Resentment', 4, 'PROVISIONAL'),
            ('DISGUST', 'AVERSION', 'Aversion', 2, 'PROVISIONAL'),
            ('DISGUST', 'CONTEMPT', 'Contempt', 4, 'PROVISIONAL'),
            ('DISGUST', 'DISAPPROVAL', 'Disapproval', 5, 'PROVISIONAL'),
            ('DISGUST', 'DISTASTE', 'Distaste', 1, 'PROVISIONAL'),
            ('DISGUST', 'REVULSION', 'Revulsion', 3, 'PROVISIONAL'),
            ('FEAR', 'ANXIETY', 'Anxiety', 1, 'FIGMA'),
            ('FEAR', 'APPREHENSION', 'Apprehension', 2, 'PROVISIONAL'),
            ('FEAR', 'DREAD', 'Dread', 4, 'PROVISIONAL'),
            ('FEAR', 'NERVOUSNESS', 'Nervousness', 3, 'PROVISIONAL'),
            ('FEAR', 'PANIC', 'Panic', 5, 'PROVISIONAL'),
            ('JOY', 'CONTENTMENT', 'Contentment', 3, 'PROVISIONAL'),
            ('JOY', 'EXCITEMENT', 'Excitement', 1, 'FIGMA'),
            ('JOY', 'PRIDE', 'Pride', 4, 'PROVISIONAL'),
            ('JOY', 'RELIEF', 'Relief', 5, 'PROVISIONAL'),
            ('JOY', 'TRIUMPH', 'Triumph', 2, 'FIGMA'),
            ('SADNESS', 'DISAPPOINTMENT', 'Disappointment', 1, 'FIGMA'),
            ('SADNESS', 'EMPATHIC_PAIN', 'Empathic pain', 3, 'FIGMA'),
            ('SADNESS', 'GUILT', 'Guilt', 5, 'FIGMA'),
            ('SADNESS', 'NOSTALGIA', 'Nostalgia', 2, 'FIGMA'),
            ('SADNESS', 'SYMPATHY', 'Sympathy', 4, 'FIGMA'),
            ('SURPRISE', 'AMAZEMENT', 'Amazement', 2, 'PROVISIONAL'),
            ('SURPRISE', 'ASTONISHMENT', 'Astonishment', 1, 'PROVISIONAL'),
            ('SURPRISE', 'CONFUSION', 'Confusion', 4, 'PROVISIONAL'),
            ('SURPRISE', 'CURIOSITY', 'Curiosity', 5, 'PROVISIONAL'),
            ('SURPRISE', 'STARTLE', 'Startle', 3, 'PROVISIONAL');

        -- ── Emotional Radar — scènes de départ (V50) : 3 lignes
        INSERT INTO games.emotional_radar_scenes (id, scene_order, media_type, prompt_text, instruction_text, media_url, media_public_id, alt_text, transcript, expected_emotion, expected_nuance, expected_intensity, explanation, active) VALUES
            ('a1e5c7d2-0000-4000-8000-000000000001', 1, 'DIALOGUE', 'Friend: "I am sorry, I have to cancel tonight."', 'Observe the situation, then identify the emotional pattern.', NULL, NULL, NULL, NULL, 'SADNESS', 'DISAPPOINTMENT', 3, 'Disappointment belongs to the sadness family because the situation involves an unmet expectation.', true),
            ('a1e5c7d2-0000-4000-8000-000000000002', 2, 'TEXT', 'You hear a strange noise at night while alone at home.', 'Observe the situation, then identify the emotional pattern.', NULL, NULL, NULL, NULL, 'FEAR', 'ANXIETY', 4, 'Anxiety appears when the threat is uncertain, invisible, or not yet confirmed.', true),
            ('a1e5c7d2-0000-4000-8000-000000000003', 3, 'IMAGE', 'A child cries alone in a quiet courtyard.', 'Observe the image, then identify the emotional pattern.', NULL, NULL, 'A child crying alone in a quiet courtyard.', NULL, 'SADNESS', 'EMPATHIC_PAIN', 3, 'Empathic pain is sadness felt for someone else''s distress rather than one''s own.', false);

        -- ── Console d'administration des jeux — banques publiées (V69) : 2 lignes
        INSERT INTO games.admin_banks (id, code, name, content_type, version, rotation_weight, status, published_at, created_by, created_at, updated_at) VALUES
            ('81000000-0000-0000-0000-000000000001', 'DECISION_FORM_A', 'Je Décide · Forme A', 'DECISION_SCENARIO', 1, 100, 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now()),
            ('81000000-0000-0000-0000-000000000002', 'EMOTIONAL_RADAR_CORE', 'Radar émotionnel · Core', 'EMOTIONAL_RADAR_SCENE', 1, 100, 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now());

        -- ── Console d'administration des jeux — contenu des banques (V69) : 32 lignes
        INSERT INTO games.admin_bank_items (bank_id, content_id, "position") VALUES
            ('81000000-0000-0000-0000-000000000001', '0f6ce46e-4b3a-5fe4-ae6b-789e840a3d75', 15),
            ('81000000-0000-0000-0000-000000000001', '11c5c597-5e93-5a1b-aa14-805d47871e81', 19),
            ('81000000-0000-0000-0000-000000000001', '14ef1a1e-4f19-5f9a-813a-d29e016ed024', 25),
            ('81000000-0000-0000-0000-000000000001', '2a108c71-8ae8-5409-a136-c57fd38752cb', 20),
            ('81000000-0000-0000-0000-000000000001', '33cbd0e7-6cba-52ce-8485-4f35d27a4ab4', 3),
            ('81000000-0000-0000-0000-000000000001', '3b8f65a0-0e3c-5e32-a2e7-584522f43cbc', 2),
            ('81000000-0000-0000-0000-000000000001', '44e694aa-8313-5dd1-9015-8e81561ad03f', 8),
            ('81000000-0000-0000-0000-000000000001', '48c98228-9651-52c0-b294-373733227320', 30),
            ('81000000-0000-0000-0000-000000000001', '4a21c7cb-81b2-5089-b53b-3e76716ba093', 27),
            ('81000000-0000-0000-0000-000000000001', '557c9f6b-5914-5beb-bffe-60715024d51a', 7),
            ('81000000-0000-0000-0000-000000000001', '577a3ef6-da98-57c0-8e9c-8be0521143ce', 22),
            ('81000000-0000-0000-0000-000000000001', '58a504a1-4260-5f88-8ded-3f03907dc852', 9),
            ('81000000-0000-0000-0000-000000000001', '63650717-5648-5191-91c5-244cbaa017f6', 16),
            ('81000000-0000-0000-0000-000000000001', '67432a01-21e8-594e-b5cc-5e34e156e24d', 11),
            ('81000000-0000-0000-0000-000000000001', '715c3b78-9dd2-5a4c-a0bc-c582ad2ed5b5', 5),
            ('81000000-0000-0000-0000-000000000001', '71b34741-0338-5fb6-aade-816894f23a66', 17),
            ('81000000-0000-0000-0000-000000000001', '86d45a99-911d-59f0-9ad8-23c8bbd5c08b', 13),
            ('81000000-0000-0000-0000-000000000001', '87e601d9-7eb5-543a-a918-190e56ad20ca', 4),
            ('81000000-0000-0000-0000-000000000001', '9005bc10-455e-5de5-87d9-5684042440e2', 29),
            ('81000000-0000-0000-0000-000000000001', '91301756-fed8-535f-807f-d36e41a520f7', 24),
            ('81000000-0000-0000-0000-000000000001', '93fbf06a-3187-5d34-9e4a-cab7bbfbcc80', 14),
            ('81000000-0000-0000-0000-000000000001', '94be291d-3ba6-57b3-b2cc-811a47cd534a', 6),
            ('81000000-0000-0000-0000-000000000001', '984ea56e-871c-5c05-bcaa-aad4ec4fc604', 18),
            ('81000000-0000-0000-0000-000000000001', '9e66ca25-b15c-54e2-b53f-efba0887f3c9', 12),
            ('81000000-0000-0000-0000-000000000001', 'a139e36e-407a-54af-a904-a0311a1c2318', 26),
            ('81000000-0000-0000-0000-000000000001', 'c5165793-f872-5631-a530-2aa0ce91adab', 28),
            ('81000000-0000-0000-0000-000000000001', 'd93713fe-e9e9-5304-831d-478c3b49d15c', 1),
            ('81000000-0000-0000-0000-000000000001', 'de763bfb-71f3-5f85-84c4-7ebd37134b99', 21),
            ('81000000-0000-0000-0000-000000000001', 'e4ac2bf3-5aa9-5286-9d37-59fb430306c8', 10),
            ('81000000-0000-0000-0000-000000000001', 'f906e2b9-1982-5dd9-9632-701a9feb1219', 23),
            ('81000000-0000-0000-0000-000000000002', 'a1e5c7d2-0000-4000-8000-000000000001', 1),
            ('81000000-0000-0000-0000-000000000002', 'a1e5c7d2-0000-4000-8000-000000000002', 2);

        -- ── Console d'administration des jeux — réglages publiés par jeu (V74, V75, V86) : 18 lignes
        INSERT INTO games.admin_configurations (id, game_type, version, values_json, status, published_at, created_by, created_at, updated_at, configuration_kind) VALUES
            ('82000000-0000-0000-0000-000000000001', 'PLANIFIK', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000002', 'MOVE_FAST', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000003', 'MEMORY_QUEST', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000004', 'DECISION', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000005', 'EMOTIONAL_REGULATION', 1, '{"orderMode": "SEQUENTIAL", "sceneCount": 3, "helpEnabled": true, "sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000006', 'CONTINUOUS_ATTENTION', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000007', 'VISUOMOTOR_COORDINATION', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000008', 'VISUOSPATIAL_MEMORY', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('82000000-0000-0000-0000-000000000009', 'DECISION_BEHAVIORAL', 1, '{"sessionEnabled": true}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'SETTINGS'),
            ('83000000-0000-0000-0000-000000000001', 'PLANIFIK', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000002', 'MOVE_FAST', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000003', 'MEMORY_QUEST', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000004', 'DECISION', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000005', 'EMOTIONAL_REGULATION', 1, '{"answerFeedback": true, "reducedMotionDefault": false, "transitionDurationMs": 900}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000006', 'CONTINUOUS_ATTENTION', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000007', 'VISUOMOTOR_COORDINATION', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000008', 'VISUOSPATIAL_MEMORY', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS'),
            ('83000000-0000-0000-0000-000000000009', 'DECISION_BEHAVIORAL', 1, '{"reducedMotionDefault": false}', 'PUBLISHED', now(), '00000000-0000-0000-0000-000000000000', now(), now(), 'MODIFIERS');

        -- ── Contrôles d'intégrité de la banque « Je Décide » (repris de V67) :
        -- échouent le démarrage plutôt que de laisser passer un catalogue tronqué.
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

    END IF;

    INSERT INTO public.seed_history (name) VALUES ('baseline-flyway-v86');
END
$seed$;
