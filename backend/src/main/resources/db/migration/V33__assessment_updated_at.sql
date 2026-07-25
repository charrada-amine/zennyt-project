-- Contrat squad web §4.1 : updatedAt devient server-owned sur Assessment.
ALTER TABLE recruitment.assessments ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE;
UPDATE recruitment.assessments SET updated_at = created_at WHERE updated_at IS NULL;
ALTER TABLE recruitment.assessments ALTER COLUMN updated_at SET NOT NULL;
