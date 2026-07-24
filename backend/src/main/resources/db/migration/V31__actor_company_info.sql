-- Projection recruteur : companyName/companyInfo (contrat squad web, §3.4 —
-- companyName/companyInfo quittent JobOffer, joints à la volée depuis la
-- projection actor comme fullName/avatarUrl le sont déjà pour les candidats.
ALTER TABLE recruitment.actors ADD COLUMN company_name VARCHAR(255);
ALTER TABLE recruitment.actors ADD COLUMN company_info TEXT;
