package com.zennyt.engagement.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Un fragment d'article, unité de recherche du volet documentaire.
 *
 * <p>Un article entier répond mal à une question précise : « pourquoi mon score a-t-il
 * changé ? » appelle le paragraphe sur le recalcul, pas les six paragraphes de l'article.
 * Un fragment ciblé se cite tel quel ; un article entier devrait être résumé, et résumer
 * c'est déjà réécrire — donc risquer de déformer.
 *
 * @param embedding  empreinte sémantique, {@code null} tant que le service n'a pas répondu
 *                   ou n'est pas configuré. La recherche bascule alors sur les mots.
 * @param sourceHash empreinte du texte du fragment, pour ne recalculer que ce qui a changé
 */
public record HelpArticleChunk(UUID id, UUID articleId, int position, String text,
                               float[] embedding, String sourceHash) {

    public HelpArticleChunk {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(articleId, "articleId");
        if (position < 0) throw new IllegalArgumentException("position négative");
        if (text == null || text.isBlank()) throw new IllegalArgumentException("texte obligatoire");
        Objects.requireNonNull(sourceHash, "sourceHash");
    }

    public boolean aUneEmpreinte() {
        return embedding != null && embedding.length > 0;
    }

    public HelpArticleChunk avecEmpreinte(float[] valeur) {
        return new HelpArticleChunk(id, articleId, position, text, valeur, sourceHash);
    }
}
