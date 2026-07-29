-- Suppression de cv_match_score (décision D1, ouverte depuis la réunion du 19/07).
--
-- Le cahier des charges Fit Score v3 ne mentionne le CV nulle part dans la formule
-- (soft × poids + hard × poids) — une omission relevée à l'époque mais jamais tranchée,
-- la colonne restant « donnée affichée, hors formule ».
--
-- Elle n'était en pratique jamais alimentée par le moteur déterministe : seul le repli
-- IA externe, supprimé en même temps que cette migration, produisait une valeur. La
-- conserver reviendrait à exposer un champ toujours nul.
--
-- L'extraction de texte de CV côté profil candidat n'est PAS concernée : elle alimente
-- le résumé IA (GET /candidates/{id}/resume), sans lien avec le Fit Score.

ALTER TABLE recruitment.fit_scores
    DROP CONSTRAINT IF EXISTS ck_fit_scores_cv_match_score;

ALTER TABLE recruitment.fit_scores
    DROP COLUMN IF EXISTS cv_match_score;
