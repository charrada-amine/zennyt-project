-- ─────────────────────────────────────────────────────────────────────────────
-- Le titre de l'offre ne doit jamais être dupliqué sur le match : il est lu à
-- la volée depuis job_offers au moment de la réponse (voir MatchController).
-- Un titre stocké ici devenait obsolète dès que le recruteur modifiait l'offre.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE recruitment.matches DROP COLUMN job_offer_title;
