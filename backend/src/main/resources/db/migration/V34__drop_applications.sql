-- L'entité Application est supprimée (contrat squad web §5.6 : le tunnel de
-- présélection/candidature n'existe plus, remplacé par le swipe mutuel ->
-- Match). SendOpportunityOfferUseCase ne se base plus que sur un Match ACTIF ;
-- la soumission d'une tentative d'évaluation ne crée plus de candidature.
ALTER TABLE recruitment.assessment_attempts DROP COLUMN IF EXISTS application_id;
DROP TABLE IF EXISTS recruitment.applications CASCADE;
