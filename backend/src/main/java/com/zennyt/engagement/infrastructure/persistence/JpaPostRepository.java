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

    @Query(value = "SELECT user_id FROM engagement.post_likes WHERE post_id = :postId", nativeQuery = true)
    List<UUID> findLikedUserIds(@Param("postId") UUID postId);

    @Modifying
    @Query(value = "INSERT INTO engagement.post_likes(post_id, user_id, created_at) " +
        "VALUES (:postId, :userId, :createdAt) ON CONFLICT DO NOTHING", nativeQuery = true)
    int addLike(@Param("postId") UUID postId, @Param("userId") UUID userId,
                @Param("createdAt") Instant createdAt);

    @Modifying
    @Query(value = "DELETE FROM engagement.post_likes WHERE post_id = :postId AND user_id = :userId",
        nativeQuery = true)
    int removeLike(@Param("postId") UUID postId, @Param("userId") UUID userId);

    @Query(value = "SELECT count(*) > 0 FROM engagement.poll_votes " +
        "WHERE post_id = :postId AND user_id = :userId", nativeQuery = true)
    boolean hasVoted(@Param("postId") UUID postId, @Param("userId") UUID userId);

    @Modifying
    @Query(value = "INSERT INTO engagement.poll_votes(post_id, user_id, option_id, created_at) " +
        "VALUES (:postId, :userId, :optionId, :createdAt)", nativeQuery = true)
    int recordVote(@Param("postId") UUID postId, @Param("userId") UUID userId,
                   @Param("optionId") UUID optionId, @Param("createdAt") Instant createdAt);
}
