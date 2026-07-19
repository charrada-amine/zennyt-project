package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.domain.model.*;
import com.zennyt.engagement.domain.vo.MediaType;
import com.zennyt.engagement.domain.vo.PostVisibility;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class PostDtos {
    private PostDtos() {}

    public record PostPage(List<PostResponse> content, PageMetaResponse page) {
        public static PostPage from(PageSlice<PostView> slice, ActorDirectory actors) {
            Map<UUID, ActorDirectory.ActorPresentation> authors = actors.presentations(
                slice.content().stream().map(view -> view.post().authorId()).toList());
            return new PostPage(slice.content().stream()
                .map(view -> PostResponse.from(view, authors.get(view.post().authorId()))).toList(),
                PageMetaResponse.from(slice));
        }
    }
    public record PostResponse(UUID id, UUID authorId, String authorName, String authorPhotoUrl,
                               PostVisibility visibility, String content, List<MediaResponse> media,
                               PollResponse poll, int likesCount, int commentsCount,
                               boolean isLikedByMe, Instant createdAt) {
        public static PostResponse from(PostView view, ActorDirectory actors) {
            return from(view, actors.presentation(view.post().authorId()));
        }

        public static PostResponse from(PostView view, ActorDirectory.ActorPresentation author) {
            Post post = view.post();
            PollResponse poll = post.poll() == null ? null
                : PollResponse.from(post.poll(), view.selectedOptionId());
            return new PostResponse(post.id(), post.authorId(), author.displayName(),
                author.photoUrl(), post.visibility(), post.content(),
                post.media().stream().map(MediaResponse::from).toList(), poll,
                (int) view.likesCount(), post.commentsCount(), view.likedByActor(), post.createdAt());
        }
    }
    public record MediaResponse(UUID id, MediaType type, String url) {
        static MediaResponse from(Post.PostMedia media) { return new MediaResponse(media.id(), media.type(), media.url()); }
    }
    public record PollResponse(UUID id, String question, List<PollOptionResponse> options, String duration) {
        static PollResponse from(Post.Poll poll, UUID selectedOptionId) {
            return new PollResponse(poll.id(), poll.question(),
                poll.options().stream().map(value -> new PollOptionResponse(value.id(), value.text(),
                    value.voteCount(), value.id().equals(selectedOptionId))).toList(),
                poll.duration());
        }
    }
    public record PollOptionResponse(UUID id, String text, int voteCount, boolean selectedByMe) {}
    public record PostCreateRequest(String content, PostVisibility visibility,
                                    List<@Valid MediaCreateRequest> media, @Valid PollCreateRequest poll) {}
    public record MediaCreateRequest(@NotNull MediaType type, @NotBlank String url) {}
    public record PollCreateRequest(@NotBlank String question,
                                    @NotEmpty List<@NotBlank String> options, String duration) {}
    public record CommentCreateRequest(@NotBlank String content) {}
    public record CommentResponse(UUID id, UUID postId, UUID authorId, String authorName,
                                  String authorPhotoUrl, String content, Instant createdAt) {
        public static CommentResponse from(Comment comment, ActorDirectory actors) {
            return new CommentResponse(comment.id(), comment.postId(), comment.authorId(),
                actors.displayName(comment.authorId()), actors.photoUrl(comment.authorId()),
                comment.content(), comment.createdAt());
        }
    }
    public record VoteRequest(@NotNull UUID optionId) {}
    public record PreferencesRequest(List<UUID> hiddenPostIds, List<UUID> blockedAuthorIds) {}
    public record PreferencesResponse(List<UUID> hiddenPostIds, List<UUID> blockedAuthorIds) {
        public static PreferencesResponse from(UserPostPreferences value) {
            return new PreferencesResponse(value.hiddenPostIds(), value.blockedAuthorIds());
        }
    }
}
