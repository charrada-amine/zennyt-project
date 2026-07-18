package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.*;

@Component
@RequiredArgsConstructor
public class PostRepositoryAdapter implements PostRepository {
    private final JpaPostRepository posts;
    private final JpaPostMediaRepository media;
    private final JpaPollOptionRepository options;

    @Override
    public Post save(Post post) {
        PostEntity entity = posts.findById(post.id()).orElseGet(() -> new PostEntity(
            post.id(), post.authorId(), post.visibility(), post.content(),
            post.poll() == null ? null : post.poll().id(),
            post.poll() == null ? null : post.poll().question(),
            post.poll() == null ? null : post.poll().duration(),
            post.commentsCount(), post.createdAt()));
        entity.update(post.authorId(), post.visibility(), post.content(),
            post.poll() == null ? null : post.poll().id(),
            post.poll() == null ? null : post.poll().question(),
            post.poll() == null ? null : post.poll().duration(), post.commentsCount());
        PostEntity saved = posts.save(entity);
        media.saveAll(post.media().stream()
            .map(value -> new PostMediaEntity(value.id(), post.id(), value.type(), value.url()))
            .toList());
        if (post.poll() != null) {
            options.saveAll(post.poll().options().stream()
                .map(value -> new PollOptionEntity(value.id(), post.id(), value.text(), value.voteCount()))
                .toList());
        }
        return toDomain(saved);
    }

    @Override public Optional<Post> findById(UUID postId) { return posts.findById(postId).map(this::toDomain); }

    @Override
    public PageSlice<Post> findFeed(UUID userId, int page, int size) {
        var result = posts.findVisibleIds(userId, PageRequest.of(page, size));
        Map<UUID, PostEntity> byId = new HashMap<>();
        posts.findAllById(result.getContent()).forEach(entity -> byId.put(entity.getId(), entity));
        List<Post> content = result.getContent().stream().map(byId::get)
            .filter(Objects::nonNull).map(this::toDomain).toList();
        return new PageSlice<>(content, page, size, result.getTotalElements());
    }

    @Override public void delete(UUID postId) { posts.deleteById(postId); }
    @Override public boolean addLike(UUID postId, UUID userId) { return posts.addLike(postId, userId, Instant.now()) == 1; }
    @Override public boolean removeLike(UUID postId, UUID userId) { return posts.removeLike(postId, userId) == 1; }
    @Override public boolean hasVoted(UUID postId, UUID userId) { return posts.hasVoted(postId, userId); }
    @Override public void recordVote(UUID postId, UUID userId, UUID optionId) {
        posts.recordVote(postId, userId, optionId, Instant.now());
    }

    private Post toDomain(PostEntity entity) {
        List<Post.PostMedia> postMedia = media.findByPostId(entity.getId()).stream()
            .map(value -> new Post.PostMedia(value.getId(), value.getType(), value.getUrl())).toList();
        Post.Poll poll = entity.getPollId() == null ? null : new Post.Poll(
            entity.getPollId(), entity.getPollQuestion(), options.findByPostId(entity.getId()).stream()
                .map(value -> new Post.PollOption(value.getId(), value.getText(), value.getVoteCount()))
                .toList(), entity.getPollDuration());
        return Post.rehydrate(entity.getId(), entity.getAuthorId(), entity.getVisibility(),
            entity.getContent(), postMedia, poll, entity.getCreatedAt(),
            posts.findLikedUserIds(entity.getId()), entity.getCommentsCount());
    }
}
