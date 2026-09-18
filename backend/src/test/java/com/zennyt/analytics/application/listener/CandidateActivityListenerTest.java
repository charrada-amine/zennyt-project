package com.zennyt.analytics.application.listener;

import com.zennyt.analytics.domain.repository.AnalyticsProjectionWriter;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.recruitment.domain.event.SwipeRecordedEvent;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class CandidateActivityListenerTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER = UUID.randomUUID();

    private final AnalyticsProjectionWriter writer = mock(AnalyticsProjectionWriter.class);
    private final CandidateActivityListener listener = new CandidateActivityListener(writer);

    @Test
    void aCandidateRightSwipeCountsAsAnApplication() {
        listener.on(SwipeRecordedEvent.of(UUID.randomUUID(), OFFER, CANDIDATE,
            SwipeSide.CANDIDATE, SwipeDirection.RIGHT));

        verify(writer).recordCandidateActivity(eq(CANDIDATE), eq(OFFER), eq("INTERESTED"), any());
    }

    @Test
    void aLeftSwipeOrARecruiterSwipeIsNotAnApplication() {
        listener.on(SwipeRecordedEvent.of(UUID.randomUUID(), OFFER, CANDIDATE,
            SwipeSide.CANDIDATE, SwipeDirection.LEFT));
        listener.on(SwipeRecordedEvent.of(UUID.randomUUID(), OFFER, CANDIDATE,
            SwipeSide.RECRUITER, SwipeDirection.RIGHT));

        verify(writer, never()).recordCandidateActivity(any(), any(), any(), any());
    }

    @Test
    void aMatchAddsMatchedAndATestAddsTestCompleted() {
        listener.on(MatchCreatedEvent.of(UUID.randomUUID(), CANDIDATE, OFFER, UUID.randomUUID(), "Dev"));
        listener.on(TestResultCompletedEvent.of(UUID.randomUUID(), CANDIDATE, UUID.randomUUID(), OFFER, 80, true));

        verify(writer).recordCandidateActivity(eq(CANDIDATE), eq(OFFER), eq("MATCHED"), any());
        verify(writer).recordCandidateActivity(eq(CANDIDATE), eq(OFFER), eq("TEST_COMPLETED"), any());
    }
}
