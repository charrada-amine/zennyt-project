package com.zennyt.shared.application.port;

/**
 * Empreinte numérique d'un texte ("embedding") — deux textes proches en sens
 * ont des empreintes proches, même sans mots communs. Utilisé pour rapprocher
 * le "rôle recherché" (texte libre) d'un candidat des noms du référentiel de
 * métiers, et pour suggérer le profil (Couche A) d'un nouveau métier proposé.
 *
 * <p>Port interchangeable : {@code null} signifie "aucun service configuré" —
 * le signal sémantique est alors simplement absent (jamais une erreur, jamais
 * un filtre bloquant).
 */
public interface EmbeddingPort {
    /** @return l'empreinte du texte, ou {@code null} si non calculable (texte vide, service indisponible). */
    float[] embed(String text);
}
