-- Codes OTP confirmant un changement de coordonnée (e-mail ou téléphone).
-- Le code en clair n'est jamais stocké : seul son empreinte SHA-256 l'est.
-- Livraison provisoire par e-mail (Resend) pour les deux types : le canal SMS
-- n'est pas encore intégré (voir IDENTITY_AUTH_README.md).
CREATE TABLE account_change_codes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    change_type VARCHAR(10) NOT NULL,
    target VARCHAR(150) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    consumed_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_account_change_attempts CHECK (attempts >= 0),
    CONSTRAINT ck_account_change_type CHECK (change_type IN ('EMAIL', 'PHONE'))
);

CREATE INDEX idx_account_change_codes_user
    ON account_change_codes(user_id, change_type);
