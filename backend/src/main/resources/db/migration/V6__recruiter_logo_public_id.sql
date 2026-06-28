-- Identifiant Cloudinary du logo d'entreprise (permet remplacement/suppression).
ALTER TABLE recruiter_onboarding_infos
    ADD COLUMN company_logo_public_id VARCHAR(255);
