-- Contrat squad web §3.1 : companyName/companyInfo quittent JobOffer (joints
-- à la volée depuis recruitment.actors, voir V31) ; fieldOfWork, currency et
-- remote sont supprimés (redondant/obsolète). updatedAt devient server-owned.
ALTER TABLE recruitment.job_offers DROP COLUMN company_name;
ALTER TABLE recruitment.job_offers DROP COLUMN company_info;
ALTER TABLE recruitment.job_offers DROP COLUMN field_of_work;
ALTER TABLE recruitment.job_offers DROP COLUMN salary_currency;
ALTER TABLE recruitment.job_offers DROP COLUMN location_remote;

ALTER TABLE recruitment.job_offers ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE;
UPDATE recruitment.job_offers SET updated_at = posted_at WHERE updated_at IS NULL;
ALTER TABLE recruitment.job_offers ALTER COLUMN updated_at SET NOT NULL;
