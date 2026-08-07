-- JobOfferStatus perd HIDDEN (contrat squad web, §3.1 : DRAFT/ACTIVE/CLOSED
-- seulement, librement réversible). Les offres HIDDEN existantes repassent CLOSED.
UPDATE recruitment.job_offers SET status = 'CLOSED' WHERE status = 'HIDDEN';
