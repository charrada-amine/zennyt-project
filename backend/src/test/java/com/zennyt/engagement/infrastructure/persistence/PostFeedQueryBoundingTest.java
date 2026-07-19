package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.vo.PostVisibility;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Prouve que charger le feed utilise un <b>nombre constant</b> de requêtes,
 * indépendant du nombre de posts : aucune fan-out par post, aucun chargement de
 * tous les likers. Test au niveau adaptateur, sans base (JPA repos mockés).
 */
class PostFeedQueryBoundingTest {

    private final UUID actor = UUID.randomUUID();

    private PostRepositoryAdapter adapterFor(int postCount) {
        JpaPostRepository posts = mock(JpaPostRepository.class);
        JpaPostMediaRepository media = mock(JpaPostMediaRepository.class);
        JpaPollOptionRepository options = mock(JpaPollOptionRepository.class);

        List<UUID> ids = new ArrayList<>();
        List<PostEntity> entities = new ArrayList<>();
        for (int i = 0; i < postCount; i++) {
            UUID id = UUID.randomUUID();
            ids.add(id);
            entities.add(new PostEntity(id, UUID.randomUUID(), PostVisibility.PUBLIC, "content",
                null, null, null, 0, Instant.now()));
        }
        when(posts.findVisibleIds(eq(actor), any(Pageable.class))).thenReturn(new PageImpl<>(ids));
        when(posts.findAllById(any())).thenReturn(entities);
        when(posts.likeStats(any(), eq(actor))).thenReturn(List.of());
        when(posts.selectedOptions(any(), eq(actor))).thenReturn(List.of());
        when(media.findByPostIdIn(any())).thenReturn(List.of());
        when(options.findByPostIdIn(any())).thenReturn(List.of());

        return new PostRepositoryAdapter(posts, media, options);
    }

    private void assertConstantQueryShape(PostRepositoryAdapter adapter, int expectedSize) {
        JpaPostRepository posts = extractPosts(adapter);
        JpaPostMediaRepository media = extractMedia(adapter);
        JpaPollOptionRepository options = extractOptions(adapter);

        List<PostView> views = adapter.findFeed(actor, 0, 50).content();
        assertThat(views).hasSize(expectedSize);

        // Chaque famille de données est chargée par lot : exactement une requête.
        verify(posts, times(1)).findVisibleIds(eq(actor), any());
        verify(posts, times(1)).findAllById(any());
        verify(posts, times(1)).likeStats(any(), eq(actor));
        verify(posts, times(1)).selectedOptions(any(), eq(actor));
        verify(media, times(1)).findByPostIdIn(any());
        verify(options, times(1)).findByPostIdIn(any());
        // Jamais de chargement per-post ni de tous les likers.
        verify(media, never()).findByPostId(any());
        verify(options, never()).findByPostId(any());
        verifyNoMoreInteractions(media, options);
    }

    @Test
    void feed_of_one_post_uses_a_constant_number_of_queries() {
        assertConstantQueryShape(adapterFor(1), 1);
    }

    @Test
    void feed_of_twenty_posts_uses_the_same_number_of_queries() {
        assertConstantQueryShape(adapterFor(20), 20);
    }

    // --- accès aux collaborateurs mockés injectés dans l'adaptateur ---
    private JpaPostRepository extractPosts(PostRepositoryAdapter a) { return field(a, "posts"); }
    private JpaPostMediaRepository extractMedia(PostRepositoryAdapter a) { return field(a, "media"); }
    private JpaPollOptionRepository extractOptions(PostRepositoryAdapter a) { return field(a, "options"); }

    @SuppressWarnings("unchecked")
    private static <T> T field(Object target, String name) {
        try {
            var f = PostRepositoryAdapter.class.getDeclaredField(name);
            f.setAccessible(true);
            return (T) f.get(target);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }
}
