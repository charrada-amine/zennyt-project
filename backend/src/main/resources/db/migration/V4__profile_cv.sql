-- CV téléversé par l'utilisateur, stocké sur Cloudinary.
-- cv_url : URL publique sécurisée ; cv_public_id : identifiant Cloudinary (suppression/remplacement).
ALTER TABLE profiles
    ADD COLUMN cv_url VARCHAR(500),
    ADD COLUMN cv_public_id VARCHAR(255);
