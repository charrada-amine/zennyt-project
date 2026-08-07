package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.ZennytApplication;
import com.zennyt.engagement.application.usecase.EnsureConversationUseCase;
import com.zennyt.engagement.application.usecase.CreatePostUseCase;
import com.zennyt.engagement.application.usecase.VoteOnPollUseCase;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.engagement.domain.vo.PostVisibility;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;

/** Tests réels des arbitres SQL ; activés explicitement contre une base PostgreSQL jetable. */
@SpringBootTest(classes = ZennytApplication.class)
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class EngagementPostgresConcurrencyTest {
    private static final int CONCURRENT_CALLS = 2;

    @DynamicPropertySource
    static void postgres(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> System.getenv("ZENNYT_TEST_POSTGRES_URL"));
        registry.add("spring.datasource.username", () -> env("ZENNYT_TEST_POSTGRES_USER", "postgres"));
        registry.add("spring.datasource.password", () -> env("ZENNYT_TEST_POSTGRES_PASSWORD", "postgres"));
    }

    @Autowired private EnsureConversationUseCase ensureConversation;
    @Autowired private EngagementApplicationRepository applications;
    @Autowired private EngagementActorRepository actors;
    @Autowired private CreatePostUseCase createPost;
    @Autowired private VoteOnPollUseCase voteOnPoll;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private ApplicationEventPublisher events;
    @Autowired private ApplicationEventRetryStore retryStore;
    @Autowired private PlatformTransactionManager transactionManager;

    @BeforeEach
    void cleanEngagementData() {
        jdbc.execute("""
            TRUNCATE engagement.pending_application_events,
                     engagement.processed_events,
                     engagement.application_projections,
                     engagement.notifications,
                     engagement.messages,
                     engagement.conversations,
                     engagement.poll_votes,
                     engagement.post_likes,
                     engagement.comments,
                     engagement.poll_options,
                     engagement.post_media,
                     engagement.posts,
                     engagement.actors,
                     recruitment.actors
            CASCADE
            """);
    }

    @Test
    void concurrent_conversation_creation_returns_one_resource_and_one_201_semantic() throws Exception {
        UUID applicationId = UUID.randomUUID();
        UUID candidateId = UUID.randomUUID();
        applications.upsert(new EngagementApplication(applicationId, UUID.randomUUID(), candidateId,
            UUID.randomUUID(), "Backend Engineer", UUID.randomUUID(), Instant.now()));

        List<Object> results = concurrently(() -> ensureConversation.execute(candidateId, applicationId));

        assertThat(results).allMatch(EnsureConversationUseCase.Result.class::isInstance);
        List<EnsureConversationUseCase.Result> conversations = results.stream()
            .map(EnsureConversationUseCase.Result.class::cast).toList();
        assertThat(conversations).filteredOn(EnsureConversationUseCase.Result::created).hasSize(1);
        assertThat(conversations).extracting(result -> result.conversation().id()).containsOnly(
            conversations.getFirst().conversation().id());
        assertThat(jdbc.queryForObject(
            "SELECT count(*) FROM engagement.conversations WHERE application_id = ?",
            Long.class, applicationId)).isEqualTo(1L);
    }

    @Test
    void concurrent_double_vote_has_one_success_one_conflict_and_fresh_counter() throws Exception {
        UUID actorId = UUID.randomUUID();
        Post created = createPost.execute(actorId, PostVisibility.PUBLIC, "Which stack?", List.of(),
            Post.Poll.create("Best stack?", List.of("Java", "Kotlin"), "3 days"));
        UUID optionId = created.poll().options().getFirst().id();

        List<Object> results = concurrently(() -> voteOnPoll.execute(actorId, created.id(), optionId));

        assertThat(results).filteredOn(PostView.class::isInstance).hasSize(1);
        assertThat(results).filteredOn(ConflictException.class::isInstance).hasSize(1);
        PostView successful = results.stream().filter(PostView.class::isInstance)
            .map(PostView.class::cast).findFirst().orElseThrow();
        assertThat(successful.selectedOptionId()).isEqualTo(optionId);
        assertThat(successful.post().poll().options())
            .filteredOn(option -> option.id().equals(optionId)).singleElement()
            .extracting(Post.PollOption::voteCount).isEqualTo(1);
        assertThat(jdbc.queryForObject(
            "SELECT vote_count FROM engagement.poll_options WHERE id = ?", Integer.class, optionId))
            .isEqualTo(1);
    }

    @Test
    void identity_projection_runs_after_commit_supports_fallback_and_never_breaks_the_emitter() {
        UUID transactionalUser = UUID.randomUUID();
        var transactionalEvent = UserAccessStateChangedEvent.of(
            transactionalUser, "CANDIDATE", true, "Ada", null, null, null, null, null,
            null, null, null, null, null, null);
        TransactionTemplate transaction = new TransactionTemplate(transactionManager);

        transaction.executeWithoutResult(status -> {
            events.publishEvent(transactionalEvent);
            assertThat(actors.findById(transactionalUser)).isEmpty();
        });
        assertThat(actors.findById(transactionalUser)).isPresent();

        UUID fallbackUser = UUID.randomUUID();
        events.publishEvent(UserAccessStateChangedEvent.of(
            fallbackUser, "STUDENT", true, "Grace", null, null, null, null, null,
            null, null, null, null, null, null));
        assertThat(actors.findById(fallbackUser)).isPresent();

        // Un événement invalide fait échouer les projections locales, pas la transaction émettrice.
        transaction.executeWithoutResult(status -> events.publishEvent(
            UserAccessStateChangedEvent.of(UUID.randomUUID(), null, true, "Invalid", null,
                null, null, null, null, null, null, null, null, null, null)));
    }

    @Test
    void failed_application_event_round_trips_through_the_durable_retry_store() {
        MatchCreatedEvent event = MatchCreatedEvent.of(
            UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), "Backend Engineer");

        retryStore.enqueue(event, "temporary failure");

        assertThat(retryStore.findDue(Instant.now().plusSeconds(1), 10))
            .singleElement()
            .satisfies(pending -> {
                assertThat(pending.event()).isEqualTo(event);
                assertThat(pending.attempts()).isZero();
            });
    }

    private List<Object> concurrently(Callable<?> operation) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(CONCURRENT_CALLS);
        CountDownLatch ready = new CountDownLatch(CONCURRENT_CALLS);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<Object>> futures = java.util.stream.IntStream.range(0, CONCURRENT_CALLS)
                .mapToObj(ignored -> executor.submit(() -> {
                    ready.countDown();
                    start.await();
                    try {
                        return operation.call();
                    } catch (RuntimeException failure) {
                        return failure;
                    }
                })).toList();
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            return futures.stream().map(future -> {
                try {
                    return future.get(10, TimeUnit.SECONDS);
                } catch (Exception exception) {
                    throw new AssertionError(exception);
                }
            }).toList();
        } finally {
            executor.shutdownNow();
        }
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
