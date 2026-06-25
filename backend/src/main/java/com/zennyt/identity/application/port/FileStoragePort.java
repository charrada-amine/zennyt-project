package com.zennyt.identity.application.port;

/**
 * Port de stockage de fichiers binaires (CV, etc.).
 *
 * <p>L'application dépend de cette abstraction, pas de Cloudinary. L'adaptateur
 * concret vit dans la couche infrastructure, ce qui garde le modèle métier pur
 * et l'implémentation de stockage interchangeable.
 */
public interface FileStoragePort {

    StoredFile upload(byte[] content, String filename, String contentType);

    void delete(String publicId);

    /**
     * @param url      URL publique sécurisée du fichier stocké
     * @param publicId identifiant chez le fournisseur, requis pour supprimer/remplacer
     */
    record StoredFile(String url, String publicId) {}
}
