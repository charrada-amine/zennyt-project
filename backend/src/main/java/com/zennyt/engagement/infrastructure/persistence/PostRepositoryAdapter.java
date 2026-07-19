package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;
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
        return toPost(saved);
    }

    @Override
    public Optional<Post> findById(UUID postId) {
        return posts.findById(postId).map(this::toPost);
    }

    @Override
    public Optional<PostView> findViewById(UUID postId, UUID actorId) {
        return posts.findById(postId)
            .map(entity -> buildViews(List.of(entity), actorId).get(0));
    }

    @Override
    public PageSlice<PostView> findFeed(UUID actorId, int page, int size) {
        var result = posts.findVisibleIds(actorId, PageRequest.of(page, size));
        List<UUID> ids = result.getContent();
        if (ids.isEmpty()) {
            return new PageSlice<>(List.of(), page, size, result.getTotalElements());
        }
        Map<UUID, PostEntity> byId = new HashMap<>();
        posts.findAllById(ids).forEach(entity -> byId.put(entity.getId(), entity));
        List<PostEntity> ordered = ids.stream().map(byId::get).filter(Objects::nonNull).toList();
        return new PageSlice<>(buildViews(ordered, actorId), page, size, result.getTotalElements());
    }

    @Override public void delete(UUID postId) { posts.deleteById(postId); }
    @Override public boolean addLike(UUID postId, UUID userId) { return posts.addLike(postId, userId, Instant.now()) == 1; }
    @Override public boolean removeLike(UUID postId, UUID userId) { return posts.removeLike(postId, userId) == 1; }

    @Override
    public boolean recordVoteIfAbsent(UUID postId, UUID userId, UUID optionId) {
        return posts.recordVoteIfAbsent(postId, userId, optionId, Instant.now()) == 1;
    }

    @Override
    public boolean incrementOptionVote(UUID optionId) {
        return posts.incrementOptionVote(optionId) == 1;
    }

    /**
     * Construit les read models d'une page en un nombre <b>constant</b> de requêtes,
     * quel que soit le nombre de posts : médias, options, stats de likes et votes de
     * l'acteur sont chargés par lots d'IDs puis regroupés en maps.
     */
    private List<PostView> buildViews(List<PostEntity> entities, UUID actorId) {
        List<UUID> ids = entities.stream().map(PostEntity::getId).toList();

        Map<UUID, List<Post.PostMedia>> mediaByPost = new HashMap<>();
        media.findByPostIdIn(ids).forEach(value -> mediaByPost
            .computeIfAbsent(value.getPostId(), key -> new ArrayList<>())
            .add(new Post.PostMedia(value.getId(), value.getType(), value.getUrl())));

        Map<UUID, List<Post.PollOption>> optionsByPost = new HashMap<>();
        options.findByPostIdIn(ids).forEach(value -> optionsByPost
            .computeIfAbsent(value.getPostId(), key -> new ArrayList<>())
            .add(new Post.PollOption(value.getId(), value.getText(), value.getVoteCount())));

        Map<UUID, Long> likesCount = new HashMap<>();
        Set<UUID> likedByActor = new HashSet<>();
        for (Object[] row : posts.likeStats(ids, actorId)) {
            UUID postId = (UUID) row[0];
            likesCount.put(postId, ((Number) row[1]).longValue());
            if (Boolean.TRUE.equals(row[2])) likedByActor.add(postId);
        }

        Map<UUID, UUID> selectedOption = new HashMap<>();
        for (Object[] row : posts.selectedOptions(ids, actorId)) {
            selectedOption.put((UUID) row[0], (UUID) row[1]);
        }

        return entities.stream().map(entity -> {
            Post post = toPost(entity, mediaByPost.getOrDefault(entity.getId(), List.of()),
                optionsByPost.getOrDefault(entity.getId(), List.of()));
            return new PostView(post, selectedOption.get(entity.getId()),
                likesCount.getOrDefault(entity.getId(), 0L), likedByActor.contains(entity.getId()));
        }).toList();
    }

    /** Agrégat pour le chemin commande : médias/options chargés isolément, sans likers. */
    private Post toPost(PostEntity entity) {
        return toPost(entity,
            media.findByPostId(entity.getId()).stream()
                .map(value -> new Post.PostMedia(value.getId(), value.getType(), value.getUrl())).toList(),
            options.findByPostId(entity.getId()).stream()
                .map(value -> new Post.PollOption(value.getId(), value.getText(), value.getVoteCount())).toList());
    }

    private Post toPost(PostEntity entity, List<Post.PostMedia> postMedia, List<Post.PollOption> pollOptions) {
        Post.Poll poll = entity.getPollId() == null ? null : new Post.Poll(
            entity.getPollId(), entity.getPollQuestion(), pollOptions, entity.getPollDuration());
        // L'agrégat reste agnostique de l'acteur : aucun liker chargé (voir PostView).
        return Post.rehydrate(entity.getId(), entity.getAuthorId(), entity.getVisibility(),
            entity.getContent(), postMedia, poll, entity.getCreatedAt(), List.of(), entity.getCommentsCount());
    }
}
