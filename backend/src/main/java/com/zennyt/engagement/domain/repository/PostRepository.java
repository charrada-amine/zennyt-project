package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.Post;

import java.util.Optional;
import java.util.UUID;

public interface PostRepository {
    Post save(Post post);
    Optional<Post> findById(UUID postId);
    PageSlice<Post> findFeed(UUID userId, int page, int size);
    void delete(UUID postId);
    boolean addLike(UUID postId, UUID userId);
    boolean removeLike(UUID postId, UUID userId);
    boolean hasVoted(UUID postId, UUID userId);
    void recordVote(UUID postId, UUID userId, UUID optionId);
}
