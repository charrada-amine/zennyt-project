package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

interface JpaPostRepository extends JpaRepository<PostEntity, UUID> {
    @Query(value = """
        SELECT post.id FROM engagement.posts post
        WHERE (post.visibility = 'PUBLIC' OR post.author_id = :userId OR EXISTS (
            SELECT 1 FROM engagement.friendships friendship
            WHERE (friendship.user_id = :userId AND friendship.friend_id = post.author_id)
               OR (friendship.friend_id = :userId AND friendship.user_id = post.author_id)))
          AND NOT EXISTS (SELECT 1 FROM engagement.hidden_posts hidden
            WHERE hidden.user_id = :userId AND hidden.post_id = post.id)
          AND NOT EXISTS (SELECT 1 FROM engagement.blocked_authors blocked
            WHERE blocked.user_id = :userId AND blocked.author_id = post.author_id)
        ORDER BY post.created_at DESC, post.id DESC
        """, countQuery = """
        SELECT count(*) FROM engagement.posts post
        WHERE (post.visibility = 'PUBLIC' OR post.author_id = :userId OR EXISTS (
            SELECT 1 FROM engagement.friendships friendship
            WHERE (friendship.user_id = :userId AND friendship.friend_id = post.author_id)
               OR (friendship.friend_id = :userId AND friendship.user_id = post.author_id)))
          AND NOT EXISTS (SELECT 1 FROM engagement.hidden_posts hidden
            WHERE hidden.user_id = :userId AND hidden.post_id = post.id)
          AND NOT EXISTS (SELECT 1 FROM engagement.blocked_authors blocked
            WHERE blocked.user_id = :userId AND blocked.author_id = post.author_id)
        """, nativeQuery = true)
    Page<UUID> findVisibleIds(@Param("userId") UUID userId, Pageable pageable);

    /**
     * Statistiques de likes bornées pour une page de posts : compteur et like de
     * l'acteur en une seule requête agrégée. Aucun chargement de tous les likers.
     * Colonnes : post_id, likes_count, liked_by_actor.
     */
    @Query(value = """
        SELECT post_id AS postId, count(*) AS likesCount,
               bool_or(user_id = :actorId) AS likedByActor
        FROM engagement.post_likes
        WHERE post_id IN (:postIds)
        GROUP BY post_id
        """, nativeQuery = true)
    List<Object[]> likeStats(@Param("postIds") List<UUID> postIds, @Param("actorId") UUID actorId);

    /** Option choisie par l'acteur pour une page de posts. Colonnes : post_id, option_id. */
    @Query(value = """
        SELECT post_id AS postId, option_id AS optionId
        FROM engagement.poll_votes
        WHERE user_id = :actorId AND post_id IN (:postIds)
        """, nativeQuery = true)
    List<Object[]> selectedOptions(@Param("postIds") List<UUID> postIds, @Param("actorId") UUID actorId);

    @Modifying
    @Query(value = "INSERT INTO engagement.post_likes(post_id, user_id, created_at) " +
        "VALUES (:postId, :userId, :createdAt) ON CONFLICT DO NOTHING", nativeQuery = true)
    int addLike(@Param("postId") UUID postId, @Param("userId") UUID userId,
                @Param("createdAt") Instant createdAt);

    @Modifying
    @Query(value = "DELETE FROM engagement.post_likes WHERE post_id = :postId AND user_id = :userId",
        nativeQuery = true)
    int removeLike(@Param("postId") UUID postId, @Param("userId") UUID userId);

    /** Réservation atomique du vote : la PK (post_id, user_id) arbitre la concurrence. */
    @Modifying
    @Query(value = "INSERT INTO engagement.poll_votes(post_id, user_id, option_id, created_at) " +
        "VALUES (:postId, :userId, :optionId, :createdAt) ON CONFLICT (post_id, user_id) DO NOTHING",
        nativeQuery = true)
    int recordVoteIfAbsent(@Param("postId") UUID postId, @Param("userId") UUID userId,
                           @Param("optionId") UUID optionId, @Param("createdAt") Instant createdAt);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE engagement.poll_options SET vote_count = vote_count + 1 WHERE id = :optionId",
        nativeQuery = true)
    int incrementOptionVote(@Param("optionId") UUID optionId);
}
