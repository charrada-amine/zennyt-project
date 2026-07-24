package com.zennyt.engagement.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Read model applicatif d'une publication pour un acteur donné.
 *
 * <p>Porte les données dépendantes de l'acteur — nombre de likes, like de l'acteur,
 * option de sondage choisie — sans les injecter dans l'agrégat {@link Post}, qui
 * reste agnostique de l'acteur courant.
 */
public record PostView(Post post, UUID selectedOptionId, long likesCount, boolean likedByActor) {
    public PostView {
        Objects.requireNonNull(post, "post");
        if (likesCount < 0) throw new IllegalArgumentException("likesCount invalide");
    }

    /** Vue d'une publication fraîchement créée : aucun like, aucun vote. */
    public static PostView fresh(Post post) {
        return new PostView(post, null, 0, false);
    }
}
