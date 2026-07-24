package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.PostDtos.PostResponse;
import com.zennyt.engagement.api.dto.PostDtos.PostPage;
import com.zennyt.engagement.application.ActorDirectory;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.vo.PostVisibility;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PostResponseMapperTest {

    private final ActorDirectory.ActorPresentation author =
        new ActorDirectory.ActorPresentation("Ada", "https://img.test/ada");

    private Post postWithTwoOptions(UUID optionA, UUID optionB) {
        Post.Poll poll = new Post.Poll(UUID.randomUUID(), "Q",
            List.of(new Post.PollOption(optionA, "A", 3), new Post.PollOption(optionB, "B", 5)), "3 days");
        return Post.rehydrate(UUID.randomUUID(), UUID.randomUUID(), PostVisibility.PUBLIC, "c",
            List.of(), poll, Instant.now(), List.of(), 0);
    }

    @Test
    void selectedByMe_is_true_only_for_the_option_the_actor_voted() {
        UUID optionA = UUID.randomUUID();
        UUID optionB = UUID.randomUUID();
        PostView view = new PostView(postWithTwoOptions(optionA, optionB), optionB, 7, true);
        PostResponse response = PostResponse.from(view, author);

        assertThat(response.likesCount()).isEqualTo(7);
        assertThat(response.isLikedByMe()).isTrue();
        assertThat(response.poll().options())
            .filteredOn(option -> option.id().equals(optionA)).singleElement()
            .satisfies(option -> assertThat(option.selectedByMe()).isFalse());
        assertThat(response.poll().options())
            .filteredOn(option -> option.id().equals(optionB)).singleElement()
            .satisfies(option -> assertThat(option.selectedByMe()).isTrue());
    }

    @Test
    void no_vote_means_no_option_selected() {
        UUID optionA = UUID.randomUUID();
        UUID optionB = UUID.randomUUID();
        PostView view = new PostView(postWithTwoOptions(optionA, optionB), null, 0, false);
        PostResponse response = PostResponse.from(view, author);

        assertThat(response.poll().options()).allSatisfy(option ->
            assertThat(option.selectedByMe()).isFalse());
    }

    @Test
    void post_page_batches_all_author_presentations_once() {
        ActorDirectory actors = mock(ActorDirectory.class);
        Post first = postWithTwoOptions(UUID.randomUUID(), UUID.randomUUID());
        Post second = postWithTwoOptions(UUID.randomUUID(), UUID.randomUUID());
        when(actors.presentations(any())).thenReturn(Map.of(
            first.authorId(), author,
            second.authorId(), author));

        PostPage response = PostPage.from(new PageSlice<>(List.of(
            PostView.fresh(first), PostView.fresh(second)), 0, 20, 2), actors);

        assertThat(response.content()).hasSize(2);
        verify(actors, times(1)).presentations(any());
        verify(actors, never()).displayName(any());
        verify(actors, never()).photoUrl(any());
        verify(actors, never()).presentation(any());
    }
}
