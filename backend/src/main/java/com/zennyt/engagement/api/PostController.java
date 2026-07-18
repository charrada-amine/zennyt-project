package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.PostDtos.*;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.application.usecase.*;
import com.zennyt.engagement.domain.model.Post;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class PostController {
    private final ListPostsUseCase listPosts;
    private final CreatePostUseCase createPost;
    private final GetPostUseCase getPost;
    private final DeletePostUseCase deletePost;
    private final LikePostUseCase likePost;
    private final UnlikePostUseCase unlikePost;
    private final ListCommentsUseCase listComments;
    private final AddCommentUseCase addComment;
    private final VoteOnPollUseCase voteOnPoll;
    private final HidePostUseCase hidePost;
    private final GetPostPreferencesUseCase getPreferences;
    private final UpdatePostPreferencesUseCase updatePreferences;
    private final BlockAuthorUseCase blockAuthor;
    private final ActorDirectory actors;

    @GetMapping("/posts") @EngagementAuthenticated
    public PostPage list(@RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size, Principal principal) {
        UUID actor = actor(principal); return PostPage.from(listPosts.execute(actor, page, size), actor, actors);
    }
    @PostMapping("/posts") @EngagementAuthenticated
    public ResponseEntity<PostResponse> create(@Valid @RequestBody PostCreateRequest request, Principal principal) {
        UUID actor = actor(principal);
        List<Post.PostMedia> media = request.media() == null ? List.of() : request.media().stream()
            .map(value -> Post.PostMedia.create(value.type(), value.url())).toList();
        Post.Poll poll = request.poll() == null ? null : Post.Poll.create(request.poll().question(), request.poll().options(), request.poll().duration());
        return ResponseEntity.status(HttpStatus.CREATED).body(PostResponse.from(
            createPost.execute(actor, request.visibility(), request.content(), media, poll), actor, actors));
    }
    @GetMapping("/posts/{postId}") @EngagementAuthenticated
    public PostResponse get(@PathVariable UUID postId, Principal principal) { UUID actor=actor(principal); return PostResponse.from(getPost.execute(actor, postId), actor, actors); }
    @DeleteMapping("/posts/{postId}") @EngagementAuthenticated
    public ResponseEntity<Void> delete(@PathVariable UUID postId, Principal principal) { deletePost.execute(actor(principal), postId); return ResponseEntity.noContent().build(); }
    @PostMapping("/posts/{postId}/likes") @EngagementAuthenticated
    public ResponseEntity<Void> like(@PathVariable UUID postId, Principal principal) { likePost.execute(actor(principal), postId); return ResponseEntity.noContent().build(); }
    @DeleteMapping("/posts/{postId}/likes") @EngagementAuthenticated
    public ResponseEntity<Void> unlike(@PathVariable UUID postId, Principal principal) { unlikePost.execute(actor(principal), postId); return ResponseEntity.noContent().build(); }
    @GetMapping("/posts/{postId}/comments") @EngagementAuthenticated
    public List<CommentResponse> comments(@PathVariable UUID postId, Principal principal) { return listComments.execute(actor(principal), postId).stream().map(value -> CommentResponse.from(value, actors)).toList(); }
    @PostMapping("/posts/{postId}/comments") @EngagementAuthenticated
    public ResponseEntity<CommentResponse> comment(@PathVariable UUID postId, @Valid @RequestBody CommentCreateRequest request, Principal principal) {
        return ResponseEntity.status(HttpStatus.CREATED).body(CommentResponse.from(addComment.execute(actor(principal), postId, request.content()), actors));
    }
    @PostMapping("/posts/{postId}/polls/vote") @EngagementAuthenticated
    public PostResponse vote(@PathVariable UUID postId, @Valid @RequestBody VoteRequest request, Principal principal) { UUID actor=actor(principal); return PostResponse.from(voteOnPoll.execute(actor, postId, request.optionId()), actor, actors); }
    @PostMapping("/posts/{postId}/hide") @EngagementAuthenticated
    public ResponseEntity<Void> hide(@PathVariable UUID postId, Principal principal) { hidePost.execute(actor(principal), postId); return ResponseEntity.noContent().build(); }
    @GetMapping("/users/me/post-preferences") @EngagementAuthenticated
    public PreferencesResponse preferences(Principal principal) { return PreferencesResponse.from(getPreferences.execute(actor(principal))); }
    @PutMapping("/users/me/post-preferences") @EngagementAuthenticated
    public PreferencesResponse update(@RequestBody PreferencesRequest request, Principal principal) { return PreferencesResponse.from(updatePreferences.execute(actor(principal), request.hiddenPostIds(), request.blockedAuthorIds())); }
    @PostMapping("/users/{authorId}/block") @EngagementAuthenticated
    public ResponseEntity<Void> block(@PathVariable UUID authorId, Principal principal) { blockAuthor.execute(actor(principal), authorId); return ResponseEntity.noContent().build(); }
    private static UUID actor(Principal principal) { return UUID.fromString(principal.getName()); }
}
