-- Identifiant Cloudinary de l'avatar du compte (permet remplacement/suppression).
ALTER TABLE users
    ADD COLUMN profile_image_public_id VARCHAR(255);
