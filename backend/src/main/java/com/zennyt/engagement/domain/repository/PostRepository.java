package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;

import java.util.Optional;
import java.util.UUID;

public interface PostRepository {
    Post save(Post post);

    /** Chemin commande : agrégat sans données dépendantes de l'acteur. */
    Optional<Post> findById(UUID postId);

    /** Chemin lecture : read model pour l'acteur courant (likes + vote). */
    Optional<PostView> findViewById(UUID postId, UUID actorId);

    /** Feed borné : nombre de requêtes constant, aucun chargement de tous les likers. */
    PageSlice<PostView> findFeed(UUID actorId, int page, int size);

    void delete(UUID postId);
    boolean addLike(UUID postId, UUID userId);
    boolean removeLike(UUID postId, UUID userId);

    /**
     * Réservation atomique du vote (INSERT ... ON CONFLICT DO NOTHING).
     * @return true si le vote a été réservé, false si l'acteur avait déjà voté.
     */
    boolean recordVoteIfAbsent(UUID postId, UUID userId, UUID optionId);

    /** Incrémente le compteur de l'option, dans la transaction de réservation. */
    boolean incrementOptionVote(UUID optionId);
}
