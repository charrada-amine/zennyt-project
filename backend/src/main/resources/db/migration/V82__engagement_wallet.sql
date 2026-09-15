-- Portefeuille utilisateur : solde en centimes (entier), écritures, carte de
-- retrait. Aucune donnée bancaire sensible n'est conservée (last4 + marque
-- seulement). Alimenté par le bonus de parrainage (hors périmètre pour l'instant).
CREATE TABLE engagement.wallets (
    user_id UUID PRIMARY KEY,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_wallets_balance_non_negative CHECK (balance_cents >= 0)
);

CREATE TABLE engagement.wallet_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    amount_cents BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL,
    kind VARCHAR(20) NOT NULL,
    label VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_wallet_transactions_kind
        CHECK (kind IN ('CREDIT', 'DEBIT', 'WITHDRAWAL'))
);

CREATE INDEX idx_wallet_transactions_user
    ON engagement.wallet_transactions(user_id, created_at DESC);

CREATE TABLE engagement.wallet_cards (
    user_id UUID PRIMARY KEY,
    last4 VARCHAR(4) NOT NULL,
    brand VARCHAR(20) NOT NULL,
    expiry_month INTEGER NOT NULL,
    expiry_year INTEGER NOT NULL,
    cardholder_name VARCHAR(150) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_wallet_cards_expiry_month CHECK (expiry_month BETWEEN 1 AND 12)
);
