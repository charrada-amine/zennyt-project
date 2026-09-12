package com.zennyt.analytics.application.listener;

import com.zennyt.analytics.domain.repository.AnalyticsProjectionWriter;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.recruitment.domain.event.SwipeRecordedEvent;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Maintient l'activité candidat du read-model Analytics.
 *
 * <p>Décision produit (à valider) : une « candidature » ({@code INTERESTED}) est
 * un swipe RIGHT du candidat sur une offre — l'entité {@code Application} ayant
 * été supprimée au profit du swipe mutuel (refonte squad web, V34). Un match
 * ajoute {@code MATCHED}, un test terminé ajoute {@code TEST_COMPLETED}.
 */
@Component
public class CandidateActivityListener {

    static final String INTERESTED = "INTERESTED";
    static final String MATCHED = "MATCHED";
    static final String TEST_COMPLETED = "TEST_COMPLETED";

    private final AnalyticsProjectionWriter writer;

    public CandidateActivityListener(AnalyticsProjectionWriter writer) {
        this.writer = writer;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(SwipeRecordedEvent event) {
        if (event.side() == SwipeSide.CANDIDATE && event.direction() == SwipeDirection.RIGHT) {
            writer.recordCandidateActivity(event.candidateId(), event.jobOfferId(), INTERESTED,
                event.occurredAt());
        }
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(MatchCreatedEvent event) {
        writer.recordCandidateActivity(event.candidateId(), event.jobOfferId(), MATCHED,
            event.occurredAt());
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(TestResultCompletedEvent event) {
        writer.recordCandidateActivity(event.candidateId(), event.jobOfferId(), TEST_COMPLETED,
            event.occurredAt());
    }
}
