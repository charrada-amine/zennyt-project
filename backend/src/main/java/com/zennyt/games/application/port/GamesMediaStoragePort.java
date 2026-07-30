package com.zennyt.games.application.port;

/**
 * Port de stockage des médias du contexte {@code games} (images et vidéos des
 * scènes « Emotional Radar »).
 *
 * <p>Chaque bounded context possède <b>son propre</b> port de stockage — c'est déjà
 * le cas d'{@code identity} ({@code FileStoragePort}) et d'{@code engagement}
 * ({@code EngagementMediaStoragePort}). {@code games} n'appelle donc jamais le code
 * d'un autre module (AGENTS.md §1) ; seul le bean partagé {@code Cloudinary} est
 * réutilisé par l'adaptateur, sans être modifié.
 */
public interface GamesMediaStoragePort {

    /** Téléverse un média et renvoie son URL publique + son identifiant distant. */
    StoredMedia upload(byte[] content, String filename, ResourceType resourceType);

    /** Média stocké : URL publique, identifiant distant, type de ressource. */
    record StoredMedia(String url, String publicId, String resourceType) {
    }

    /** Types de médias qu'une scène peut porter. */
    enum ResourceType {
        IMAGE,
        VIDEO
    }
}
