package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Un article de la documentation destinée aux utilisateurs.
 *
 * <p>Source du volet documentaire de l'agent d'aide. Les articles sont rédigés dans des
 * fichiers de ressources puis projetés ici : un texte se relit et se corrige en revue,
 * ce qu'une suite d'INSERT rendrait pénible.
 *
 * <p>Le {@code contentHash} dit si l'article a changé depuis la dernière synchronisation.
 * Comparer les dates ne suffirait pas — un fichier peut être réécrit à l'identique par un
 * outil de formatage, et on recalculerait alors des empreintes numériques pour rien.
 */
public record HelpArticle(UUID id, String slug, String locale, Audience audience,
                          String category, String title, String body,
                          String contentHash, Instant updatedAt) {

    /** À qui l'article s'adresse — un article de création d'offre n'a rien à dire à un candidat. */
    public enum Audience { CANDIDATE, RECRUITER, BOTH }

    public HelpArticle {
        Objects.requireNonNull(id, "id");
        if (slug == null || slug.isBlank()) throw new IllegalArgumentException("slug obligatoire");
        if (locale == null || locale.isBlank()) throw new IllegalArgumentException("locale obligatoire");
        Objects.requireNonNull(audience, "audience");
        if (title == null || title.isBlank()) throw new IllegalArgumentException("titre obligatoire");
        if (body == null || body.isBlank()) throw new IllegalArgumentException("corps obligatoire");
        Objects.requireNonNull(contentHash, "contentHash");
        Objects.requireNonNull(updatedAt, "updatedAt");
    }

    /** L'article est-il lisible par ce public ? */
    public boolean concerne(Audience lecteur) {
        return audience == Audience.BOTH || audience == lecteur;
    }
}
