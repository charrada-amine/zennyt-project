-- Devise et périodicité du salaire (maquette 213). Le montant reste brut
-- (gross) dans salary_min/salary_max ; ces colonnes portent l'affichage.
-- Valeurs par défaut pour les offres existantes, puis contraintes.
ALTER TABLE recruitment.job_offers
    ADD COLUMN salary_currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    ADD COLUMN salary_period VARCHAR(10) NOT NULL DEFAULT 'MONTHLY';

ALTER TABLE recruitment.job_offers
    ADD CONSTRAINT ck_job_offers_salary_currency
        CHECK (salary_currency IN ('EUR', 'USD', 'GBP', 'MAD', 'TND'));

ALTER TABLE recruitment.job_offers
    ADD CONSTRAINT ck_job_offers_salary_period
        CHECK (salary_period IN ('MONTHLY', 'YEARLY'));
