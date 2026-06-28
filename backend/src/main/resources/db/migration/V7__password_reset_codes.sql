-- Codes OTP de réinitialisation de mot de passe (envoyés par e-mail via Resend).
-- Le code en clair n'est jamais stocké : seul son empreinte SHA-256 (hex) l'est.
CREATE TABLE password_reset_codes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    consumed_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_password_reset_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_password_reset_codes_user ON password_reset_codes(user_id);
