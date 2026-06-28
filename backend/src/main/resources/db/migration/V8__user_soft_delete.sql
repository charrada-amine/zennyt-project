-- Suppression logique des comptes : la ligne est conservée (intégrité référentielle),
-- l'e-mail est anonymisé à la suppression pour libérer l'adresse d'origine.
ALTER TABLE users
    ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
