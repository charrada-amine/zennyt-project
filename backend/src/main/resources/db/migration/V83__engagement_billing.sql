-- Abonnements et achats via App Store / Google Play. Aucun reçu brut n'est
-- conservé : seulement l'identifiant de transaction et le produit. L'état réel
-- de l'abonnement fait foi côté Apple/Google (vérification serveur à brancher).
CREATE TABLE engagement.subscriptions (
    user_id UUID PRIMARY KEY,
    plan_code VARCHAR(60) NOT NULL,
    status VARCHAR(20) NOT NULL,
    store VARCHAR(10) NOT NULL,
    original_transaction_id VARCHAR(200),
    purchased_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    auto_renewing BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_subscriptions_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'CANCELLED')),
    CONSTRAINT ck_subscriptions_store CHECK (store IN ('APPLE', 'GOOGLE'))
);

CREATE TABLE engagement.store_purchases (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    product_id VARCHAR(60) NOT NULL,
    kind VARCHAR(20) NOT NULL,
    store VARCHAR(10) NOT NULL,
    transaction_id VARCHAR(200) NOT NULL UNIQUE,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    purchased_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_store_purchases_kind CHECK (kind IN ('SUBSCRIPTION', 'CONSUMABLE')),
    CONSTRAINT ck_store_purchases_store CHECK (store IN ('APPLE', 'GOOGLE'))
);

CREATE INDEX idx_store_purchases_user ON engagement.store_purchases(user_id);
