CREATE TABLE social_identities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(20) NOT NULL,
    provider_subject VARCHAR(255) NOT NULL,
    email VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_social_identities_provider CHECK (provider IN ('GOOGLE', 'APPLE')),
    CONSTRAINT uq_social_identities_provider_subject UNIQUE (provider, provider_subject),
    CONSTRAINT uq_social_identities_user_provider UNIQUE (user_id, provider)
);

CREATE INDEX idx_social_identities_user ON social_identities (user_id);
