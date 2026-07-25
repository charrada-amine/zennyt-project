package com.zennyt.recruitment.application.port;

/**
 * Port d'extraction de texte depuis un fichier source uploadé (génération de
 * test IA "From File"). Implémenté par un adaptateur PDF en
 * {@code infrastructure.ai} — pas de variante nécessaire (traitement local,
 * pas d'appel à un fournisseur externe), mais reste un port pour ne pas
 * accrocher l'use case à une bibliothèque de parsing concrète.
 */
public interface SourceDocumentExtractorPort {

    /** @throws IllegalArgumentException si le contenu n'est pas un format supporté ou ne contient aucun texte */
    String extractText(byte[] content);
}
