-- Consentement à la surveillance anti-fraude, exigé avant toute écriture de tentative
-- (règle du cadrage 16/07, portée par l'entité AssessmentAttemptEntity depuis a52ecf0
-- mais jamais migrée : ddl-auto validate échouait sur toute base fraîche).
ALTER TABLE recruitment.assessment_attempts
    ADD COLUMN monitoring_consent BOOLEAN NOT NULL DEFAULT FALSE;
