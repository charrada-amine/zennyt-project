package com.zennyt.identity.application.port;

/**
 * Port de stockage de fichiers binaires (CV, avatars, logos d'entreprise).
 *
 * <p>L'application dépend de cette abstraction, pas de Cloudinary. L'adaptateur
 * concret vit dans la couche infrastructure, ce qui garde le modèle métier pur
 * et l'implémentation de stockage interchangeable.
 */
public interface FileStoragePort {

    /**
     * @param folder       dossier logique chez le fournisseur (ex. {@code zennyt/cv})
     * @param resourceType nature du fichier : {@link ResourceType#RAW} pour les documents
     *                     (PDF/DOC), {@link ResourceType#IMAGE} pour les images
     */
    StoredFile upload(byte[] content, String filename, String contentType,
                      String folder, ResourceType resourceType);

    void delete(String publicId, ResourceType resourceType);

    /** Nature du fichier stocké, qui conditionne le traitement côté fournisseur. */
    enum ResourceType { RAW, IMAGE }

    /**
     * @param url      URL publique sécurisée du fichier stocké
     * @param publicId identifiant chez le fournisseur, requis pour supprimer/remplacer
     */
    record StoredFile(String url, String publicId) {}
}
