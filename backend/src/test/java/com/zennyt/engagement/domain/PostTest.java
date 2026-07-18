package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.vo.MediaType;
import com.zennyt.engagement.domain.vo.PostVisibility;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class PostTest {
    @Test void accepts_media_only_post() {
        Post post = Post.create(UUID.randomUUID(), PostVisibility.PUBLIC, null,
            List.of(Post.PostMedia.create(MediaType.IMAGE, "https://img.test/a.png")), null);
        assertNull(post.content());
        assertEquals(1, post.media().size());
    }

    @Test void rejects_empty_post() {
        assertThrows(IllegalArgumentException.class,
            () -> Post.create(UUID.randomUUID(), PostVisibility.PUBLIC, " ", List.of(), null));
    }

    @Test void poll_vote_updates_only_selected_option() {
        Post.Poll poll = Post.Poll.create("Choix ?", List.of("A", "B"), "3 days");
        Post post = Post.create(UUID.randomUUID(), PostVisibility.PUBLIC, null, List.of(), poll);
        UUID selected = poll.options().getFirst().id();
        post.voteOnPoll(selected);
        assertEquals(1, post.poll().options().getFirst().voteCount());
        assertEquals(0, post.poll().options().getLast().voteCount());
    }
}
