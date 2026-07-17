package com.zennyt.recruitment.application;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Alimente le read-model soft-skills puis recalcule les offres actives du candidat. */
@Component
public class GameSoftSkillsListener {
    private final SoftSkillsProjectionRepository projections;
    private final RecomputeFitScoresUseCase recompute;
    private final FitScoreRecomputeWorker worker;

    public GameSoftSkillsListener(SoftSkillsProjectionRepository projections,
                                  RecomputeFitScoresUseCase recompute,
                                  FitScoreRecomputeWorker worker) {
        this.projections = projections;
        this.recompute = recompute;
        this.worker = worker;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(GameResultRecordedEvent event) {
        int score = Math.max(0, Math.min(100, (int) Math.round(event.normalizedScore())));
        projections.save(new SoftSkillsProjection(event.playerId(), score, event.occurredAt()));
        recompute.pairsForCandidate(event.playerId()).forEach(worker::submit);
    }
}
