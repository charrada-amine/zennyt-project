-- Seed du référentiel métiers depuis Zennyt_Matrice_Finale_Ponderation_Metiers_v4.1.pdf
-- 9 métiers transverses + 133 métiers sectoriels sur 12 secteurs.
-- calibrated=false partout : la matrice est explicitement "v1 — non calibrée,
-- à valider en atelier RH" (matrice p.3 et p.31).

-- ═══════════════ Métiers transverses (sector = NULL) ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Commercial / Business Developer', NULL, 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'RH / Talent Acquisition', NULL, 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Finance / Comptabilité', NULL, 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Marketing / Communication', NULL, 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Support client / Service client', NULL, 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Management général / Direction', NULL, 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Data Analyst / Data Scientist', NULL, 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de projet / Product Manager', NULL, 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Consultant', NULL, 'ANALYTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : IT, AI & Fintech ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Développeur', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur DevOps / Cloud', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur IA / Machine Learning', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Data Engineer', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Architecte Solutions', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Analyste Cybersécurité', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur QA / Testeur', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Administrateur systèmes & réseaux', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur Blockchain', 'IT, AI & Fintech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'UX/UI Designer', 'IT, AI & Fintech', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Product Owner', 'IT, AI & Fintech', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Scrum Master / Agile Coach', 'IT, AI & Fintech', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Analyste Fintech / Quant', 'IT, AI & Fintech', 'ANALYTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Consulting & Services ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Auditeur', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Business Analyst', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé d''études', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Consultant en organisation', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de mission', 'Consulting & Services', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Consultant SI / Digital', 'Consulting & Services', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Consultant RH', 'Consulting & Services', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Consultant financier', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de mission conseil', 'Consulting & Services', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Assistant consultant / Analyste junior', 'Consulting & Services', 'ANALYTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Finance ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Analyste financier', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Trader', 'Finance', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Risk Manager', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Conseiller clientèle bancaire', 'Finance', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Contrôleur de gestion', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Comptable', 'Finance', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Trésorier', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Gestionnaire de portefeuille / Asset manager', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de conformité / Compliance officer', 'Finance', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Analyste crédit', 'Finance', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Actuaire', 'Finance', 'TECHNIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Health & Biotech ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Infirmier', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Médecin', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chercheur biotech', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien de laboratoire', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Pharmacien', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Kinésithérapeute', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Sage-femme', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Aide-soignant', 'Health & Biotech', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur biomédical', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Bio-informaticien / Data scientist santé', 'Health & Biotech', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable affaires réglementaires santé', 'Health & Biotech', 'ANALYTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Marketing & Communication ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Chargé de communication', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Growth hacker', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Community manager', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Brand manager', 'Marketing & Communication', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé d''études marketing', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Traffic manager / SEA specialist', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'SEO specialist', 'Marketing & Communication', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Graphiste / Designer', 'Marketing & Communication', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Content manager / Rédacteur', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de produit marketing', 'Marketing & Communication', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Attaché de presse / RP', 'Marketing & Communication', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Motion designer', 'Marketing & Communication', 'ARTISTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Industry ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Ingénieur de production', 'Industry', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien de maintenance', 'Industry', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable qualité', 'Industry', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur méthodes', 'Industry', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable d''atelier / production', 'Industry', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Opérateur de production', 'Industry', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur R&D industriel', 'Industry', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable supply chain', 'Industry', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien qualité', 'Industry', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur process', 'Industry', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable HSE industriel', 'Industry', 'MANAGERIAL', false, 'APPROVED', now());

-- ═══════════════ Secteur : Energy & Sustainable Development ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Ingénieur énergie', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de projet RSE', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien réseaux énergie', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Analyste environnemental', 'Energy & Sustainable Development', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable HSE', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur énergies renouvelables', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé d''affaires énergie', 'Energy & Sustainable Development', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien photovoltaïque / éolien', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable développement durable', 'Energy & Sustainable Development', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur efficacité énergétique', 'Energy & Sustainable Development', 'TECHNIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Transport & Mobility ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Conducteur / Chauffeur professionnel', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur logistique', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable exploitation transport', 'Transport & Mobility', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien maintenance flotte', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de planification transport', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Agent de quai / Magasinier', 'Transport & Mobility', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Pilote / Agent navigant', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur mobilité / transport', 'Transport & Mobility', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable logistique', 'Transport & Mobility', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Contrôleur de gestion transport', 'Transport & Mobility', 'ANALYTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Construction & Infrastructure ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Ingénieur BTP', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Conducteur de travaux', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Architecte', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Métreur', 'Construction & Infrastructure', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de chantier', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ouvrier / Compagnon qualifié', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Ingénieur structure', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Économiste de la construction', 'Construction & Infrastructure', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Technicien bureau d''études', 'Construction & Infrastructure', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable HSE chantier', 'Construction & Infrastructure', 'MANAGERIAL', false, 'APPROVED', now());

-- ═══════════════ Secteur : Retail & e-commerce ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Conseiller de vente', 'Retail & e-commerce', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable de magasin', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Category manager', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé logistique e-commerce', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable e-commerce', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Acheteur / Buyer', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Merchandiser', 'Retail & e-commerce', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de rayon', 'Retail & e-commerce', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Gestionnaire de stock', 'Retail & e-commerce', 'CONVENTIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'UX/UI e-commerce', 'Retail & e-commerce', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Styliste / Designer produit', 'Retail & e-commerce', 'ARTISTIQUE', false, 'APPROVED', now());

-- ═══════════════ Secteur : Hotel & Catering ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Réceptionniste', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de cuisine', 'Hotel & Catering', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Responsable restauration (F&B manager)', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Concierge', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Directeur d''hôtel', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Serveur / Maître d''hôtel', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef de rang', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Gouvernante générale', 'Hotel & Catering', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Barman / Sommelier', 'Hotel & Catering', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Commis de cuisine', 'Hotel & Catering', 'CONVENTIONNEL', false, 'APPROVED', now());

-- ═══════════════ Secteur : Media, Culture & Entertainment ═══════════════
INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at) VALUES
(gen_random_uuid(), 'Journaliste', 'Media, Culture & Entertainment', 'ANALYTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Réalisateur / Producteur', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Monteur / Technicien audiovisuel', 'Media, Culture & Entertainment', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de programmation culturelle', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chargé de communication digitale (média)', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Scénariste', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Chef opérateur / Cadreur', 'Media, Culture & Entertainment', 'TECHNIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Régisseur', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Attaché de production', 'Media, Culture & Entertainment', 'MANAGERIAL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Community manager média', 'Media, Culture & Entertainment', 'RELATIONNEL', false, 'APPROVED', now()),
(gen_random_uuid(), 'Directeur artistique', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Illustrateur / Concept artist', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Compositeur / Sound designer', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', now()),
(gen_random_uuid(), 'Photographe', 'Media, Culture & Entertainment', 'ARTISTIQUE', false, 'APPROVED', now());

-- ═══════════════ Intitulés de poste par niveau (annexe v4.1, p.32) ═══════════════
-- 13 métiers pour lesquels un intitulé usuel diffère du simple "Métier + Niveau".
-- N'affecte que le libellé affiché — pas la pondération.

UPDATE recruitment.job_positions SET
    junior_label = 'Apprenti / Ouvrier débutant', senior_label = 'Compagnon confirmé',
    lead_label = 'Chef d''équipe', manager_label = 'Chef de chantier'
WHERE name = 'Ouvrier / Compagnon qualifié' AND sector = 'Construction & Infrastructure';

UPDATE recruitment.job_positions SET
    junior_label = 'Opérateur débutant', senior_label = 'Opérateur confirmé',
    lead_label = 'Chef d''équipe production', manager_label = 'Chef d''atelier'
WHERE name = 'Opérateur de production' AND sector = 'Industry';

UPDATE recruitment.job_positions SET
    junior_label = 'Technicien débutant', senior_label = 'Technicien confirmé',
    lead_label = 'Technicien référent / Chef d''équipe', manager_label = 'Responsable maintenance'
WHERE name = 'Technicien de maintenance' AND sector = 'Industry';

UPDATE recruitment.job_positions SET
    junior_label = 'Chauffeur débutant', senior_label = 'Chauffeur confirmé',
    lead_label = 'Chauffeur référent / Chef de file', manager_label = 'Responsable parc'
WHERE name = 'Conducteur / Chauffeur professionnel' AND sector = 'Transport & Mobility';

UPDATE recruitment.job_positions SET
    junior_label = 'Agent débutant', senior_label = 'Agent confirmé',
    lead_label = 'Chef d''équipe quai', manager_label = 'Responsable entrepôt'
WHERE name = 'Agent de quai / Magasinier' AND sector = 'Transport & Mobility';

UPDATE recruitment.job_positions SET
    junior_label = 'Technicien débutant', senior_label = 'Technicien confirmé',
    lead_label = 'Technicien référent / Chef d''équipe', manager_label = 'Responsable maintenance flotte'
WHERE name = 'Technicien maintenance flotte' AND sector = 'Transport & Mobility';

UPDATE recruitment.job_positions SET
    junior_label = 'Copilote', senior_label = 'Commandant de bord confirmé',
    lead_label = 'Commandant de bord senior', manager_label = 'Chef pilote'
WHERE name = 'Pilote / Agent navigant' AND sector = 'Transport & Mobility';

UPDATE recruitment.job_positions SET
    junior_label = 'Gestionnaire stock débutant', senior_label = 'Gestionnaire stock confirmé',
    lead_label = 'Chef d''équipe logistique', manager_label = 'Responsable entrepôt'
WHERE name = 'Gestionnaire de stock' AND sector = 'Retail & e-commerce';

UPDATE recruitment.job_positions SET
    junior_label = 'Conseiller débutant', senior_label = 'Conseiller confirmé',
    lead_label = 'Conseiller référent', manager_label = 'Adjoint responsable magasin'
WHERE name = 'Conseiller de vente' AND sector = 'Retail & e-commerce';

UPDATE recruitment.job_positions SET
    junior_label = 'Commis débutant', senior_label = 'Commis confirmé / Demi-chef de partie',
    lead_label = 'Chef de partie', manager_label = 'Second de cuisine'
WHERE name = 'Commis de cuisine' AND sector = 'Hotel & Catering';

UPDATE recruitment.job_positions SET
    junior_label = 'Serveur débutant', senior_label = 'Serveur confirmé',
    lead_label = 'Chef de rang', manager_label = 'Maître d''hôtel'
WHERE name = 'Serveur / Maître d''hôtel' AND sector = 'Hotel & Catering';

UPDATE recruitment.job_positions SET
    junior_label = 'Barman débutant', senior_label = 'Barman confirmé / Sommelier',
    lead_label = 'Chef barman', manager_label = 'Responsable bar'
WHERE name = 'Barman / Sommelier' AND sector = 'Hotel & Catering';

UPDATE recruitment.job_positions SET
    junior_label = 'Technicien débutant', senior_label = 'Technicien confirmé',
    lead_label = 'Technicien référent / Chef d''équipe', manager_label = 'Responsable réseaux'
WHERE name = 'Technicien réseaux énergie' AND sector = 'Energy & Sustainable Development';
