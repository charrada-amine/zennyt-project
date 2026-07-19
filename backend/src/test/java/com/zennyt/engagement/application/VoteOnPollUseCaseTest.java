package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.GetPostUseCase;
import com.zennyt.engagement.application.usecase.VoteOnPollUseCase;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.engagement.domain.vo.PostVisibility;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class VoteOnPollUseCaseTest {

    private static final UUID ACTOR = UUID.randomUUID();
    private static final UUID POST = UUID.randomUUID();
    private static final UUID OPTION_A = UUID.randomUUID();
    private static final UUID OPTION_B = UUID.randomUUID();

    private PostRepository posts;
    private GetPostUseCase getPost;
    private VoteOnPollUseCase useCase;

    @BeforeEach
    void setUp() {
        posts = mock(PostRepository.class);
        getPost = mock(GetPostUseCase.class);
        useCase = new VoteOnPollUseCase(posts, getPost);
    }

    private Post postWithPoll() {
        Post.Poll poll = new Post.Poll(UUID.randomUUID(), "Best stack?",
            List.of(new Post.PollOption(OPTION_A, "A", 0), new Post.PollOption(OPTION_B, "B", 0)), "3 days");
        return Post.rehydrate(POST, UUID.randomUUID(), PostVisibility.PUBLIC, "content",
            List.of(), poll, Instant.now(), List.of(), 0);
    }

    @Test
    void first_vote_reserves_increments_and_returns_selected_view() {
        when(getPost.execute(ACTOR, POST)).thenReturn(PostView.fresh(postWithPoll()));
        when(posts.recordVoteIfAbsent(POST, ACTOR, OPTION_A)).thenReturn(true);
        when(posts.incrementOptionVote(OPTION_A)).thenReturn(true);
        Post voted = postWithPoll();
        voted.voteOnPoll(OPTION_A);
        when(posts.findViewById(POST, ACTOR)).thenReturn(Optional.of(new PostView(voted, OPTION_A, 0, false)));

        PostView result = useCase.execute(ACTOR, POST, OPTION_A);

        assertThat(result.selectedOptionId()).isEqualTo(OPTION_A);
        assertThat(result.post().poll().options()).filteredOn(option -> option.id().equals(OPTION_A))
            .singleElement().extracting(Post.PollOption::voteCount).isEqualTo(1);
        verify(posts).recordVoteIfAbsent(POST, ACTOR, OPTION_A);
        verify(posts).incrementOptionVote(OPTION_A);
    }

    @Test
    void second_vote_is_rejected_with_conflict_and_does_not_increment() {
        when(getPost.execute(ACTOR, POST)).thenReturn(PostView.fresh(postWithPoll()));
        when(posts.recordVoteIfAbsent(POST, ACTOR, OPTION_A)).thenReturn(false);

        assertThatThrownBy(() -> useCase.execute(ACTOR, POST, OPTION_A))
            .isInstanceOf(ConflictException.class);

        verify(posts, never()).incrementOptionVote(any());
        verify(posts, never()).findViewById(any(), any());
    }

    @Test
    void concurrent_double_vote_yields_exactly_one_success_and_one_conflict() {
        when(getPost.execute(ACTOR, POST)).thenReturn(PostView.fresh(postWithPoll()));
        // La réservation atomique n'accorde qu'une seule insertion : 1er true, 2e false.
        when(posts.recordVoteIfAbsent(POST, ACTOR, OPTION_A)).thenReturn(true, false);
        when(posts.incrementOptionVote(OPTION_A)).thenReturn(true);
        when(posts.findViewById(POST, ACTOR))
            .thenReturn(Optional.of(new PostView(postWithPoll(), OPTION_A, 0, false)));

        useCase.execute(ACTOR, POST, OPTION_A);
        assertThatThrownBy(() -> useCase.execute(ACTOR, POST, OPTION_A))
            .isInstanceOf(ConflictException.class);

        verify(posts, times(1)).incrementOptionVote(OPTION_A);
    }

    @Test
    void invalid_option_is_rejected_before_any_reservation() {
        when(getPost.execute(ACTOR, POST)).thenReturn(PostView.fresh(postWithPoll()));

        assertThatThrownBy(() -> useCase.execute(ACTOR, POST, UUID.randomUUID()))
            .isInstanceOf(NotFoundException.class);

        verify(posts, never()).recordVoteIfAbsent(any(), any(), any());
    }

    @Test
    void post_without_poll_is_rejected() {
        Post noPoll = Post.rehydrate(POST, UUID.randomUUID(), PostVisibility.PUBLIC, "text",
            List.of(), null, Instant.now(), List.of(), 0);
        when(getPost.execute(ACTOR, POST)).thenReturn(PostView.fresh(noPoll));

        assertThatThrownBy(() -> useCase.execute(ACTOR, POST, OPTION_A))
            .isInstanceOf(NotFoundException.class);

        verify(posts, never()).recordVoteIfAbsent(any(), any(), any());
    }
}
