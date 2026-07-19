package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.MediaType;
import com.zennyt.engagement.domain.vo.PostVisibility;

import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/** Publication sociale et éventuel sondage, sans dépendance framework. */
public class Post {
    private final UUID id;
    private final UUID authorId;
    private final PostVisibility visibility;
    private final String content;
    private final List<PostMedia> media;
    private Poll poll;
    private final Instant createdAt;
    private final List<UUID> likedByUserIds;
    private int commentsCount;

    private Post(UUID id, UUID authorId, PostVisibility visibility, String content,
                 List<PostMedia> media, Poll poll, Instant createdAt,
                 List<UUID> likedByUserIds, int commentsCount) {
        this.id = Objects.requireNonNull(id, "id");
        this.authorId = Objects.requireNonNull(authorId, "authorId");
        this.visibility = visibility == null ? PostVisibility.PUBLIC : visibility;
        this.content = normalize(content);
        this.media = List.copyOf(media == null ? List.of() : media);
        this.poll = poll;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.likedByUserIds = List.copyOf(likedByUserIds == null ? List.of() : likedByUserIds);
        if (commentsCount < 0) throw new IllegalArgumentException("commentsCount invalide");
        this.commentsCount = commentsCount;
        if (this.content == null && this.media.isEmpty() && poll == null) {
            throw new IllegalArgumentException("Une publication doit contenir du texte, un média ou un sondage");
        }
    }

    public static Post create(UUID authorId, PostVisibility visibility, String content,
                              List<PostMedia> media, Poll poll) {
        return new Post(UUID.randomUUID(), authorId, visibility, content, media, poll,
            Instant.now(), List.of(), 0);
    }

    public static Post rehydrate(UUID id, UUID authorId, PostVisibility visibility, String content,
                                 List<PostMedia> media, Poll poll, Instant createdAt,
                                 List<UUID> likedByUserIds, int commentsCount) {
        return new Post(id, authorId, visibility, content, media, poll,
            createdAt, likedByUserIds, commentsCount);
    }

    public void voteOnPoll(UUID optionId) {
        if (poll == null) throw new IllegalStateException("Cette publication n'a pas de sondage");
        poll = poll.vote(optionId);
    }

    public void incrementCommentsCount() { commentsCount++; }

    public UUID id() { return id; }
    public UUID authorId() { return authorId; }
    public PostVisibility visibility() { return visibility; }
    public String content() { return content; }
    public List<PostMedia> media() { return media; }
    public Poll poll() { return poll; }
    public Instant createdAt() { return createdAt; }
    public List<UUID> likedByUserIds() { return likedByUserIds; }
    public int likesCount() { return likedByUserIds.size(); }
    public int commentsCount() { return commentsCount; }
    public boolean likedBy(UUID userId) { return likedByUserIds.contains(userId); }

    private static String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public record PostMedia(UUID id, MediaType type, String url) {
        public PostMedia {
            Objects.requireNonNull(id, "id");
            Objects.requireNonNull(type, "type");
            if (url == null || url.isBlank()) throw new IllegalArgumentException("URL média obligatoire");
        }
        public static PostMedia create(MediaType type, String url) {
            return new PostMedia(UUID.randomUUID(), type, url);
        }
    }

    public record Poll(UUID id, String question, List<PollOption> options, String duration) {
        public Poll {
            Objects.requireNonNull(id, "id");
            if (question == null || question.isBlank()) throw new IllegalArgumentException("Question obligatoire");
            options = List.copyOf(options);
            if (options.size() < 2) throw new IllegalArgumentException("Deux options minimum");
            duration = duration == null || duration.isBlank() ? "3 days" : duration;
        }
        public static Poll create(String question, List<String> optionTexts, String duration) {
            return new Poll(UUID.randomUUID(), question,
                optionTexts.stream().map(text -> new PollOption(UUID.randomUUID(), text, 0)).toList(),
                duration);
        }
        public Poll vote(UUID optionId) {
            if (options.stream().noneMatch(option -> option.id().equals(optionId))) {
                throw new IllegalArgumentException("Option de sondage invalide");
            }
            return new Poll(id, question, options.stream()
                .map(option -> option.id().equals(optionId)
                    ? new PollOption(option.id(), option.text(), option.voteCount() + 1) : option)
                .toList(), duration);
        }
    }

    public record PollOption(UUID id, String text, int voteCount) {
        public PollOption {
            Objects.requireNonNull(id, "id");
            if (text == null || text.isBlank()) throw new IllegalArgumentException("Option obligatoire");
            if (voteCount < 0) throw new IllegalArgumentException("voteCount invalide");
        }
    }
}
