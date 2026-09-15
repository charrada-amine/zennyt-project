-- Préférences d'application synchronisées côté serveur (accessibilité +
-- notifications). Une ligne par compte, créée à la première écriture ; en son
-- absence l'API renvoie les valeurs par défaut (pas de backfill nécessaire).
CREATE TABLE user_preferences (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    high_contrast BOOLEAN NOT NULL DEFAULT TRUE,
    text_size_px INTEGER NOT NULL DEFAULT 18,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_user_preferences_text_size CHECK (text_size_px BETWEEN 10 AND 30)
);
