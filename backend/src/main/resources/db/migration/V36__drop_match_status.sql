-- Match est binaire (contrat squad web §6.1) : il existe ou n'existe pas,
-- pas de statut intermédiaire. Aucune valeur autre qu'ACTIVE n'a jamais été
-- écrite (EXPIRED/CLOSED n'avaient pas de logique de transition).
ALTER TABLE recruitment.matches DROP COLUMN status;
