package com.zennyt.recruitment.application;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.recruitment.application.usecase.GenerateSoftSkillsSummaryUseCase;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Alimente le read-model soft-skills puis recalcule les offres actives du
 * candidat et régénère son résumé IA "Soft Skills Summary".
 */
@Component
public class GameSoftSkillsListener {
    private final SoftSkillsProjectionRepository projections;
    private final RecomputeFitScoresUseCase recompute;
    private final FitScoreEnqueuer enqueuer;
    private final GenerateSoftSkillsSummaryUseCase generateSummary;

    public GameSoftSkillsListener(SoftSkillsProjectionRepository projections,
                                  RecomputeFitScoresUseCase recompute,
                                  FitScoreEnqueuer enqueuer,
                                  GenerateSoftSkillsSummaryUseCase generateSummary) {
        this.projections = projections;
        this.recompute = recompute;
        this.enqueuer = enqueuer;
        this.generateSummary = generateSummary;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(GameResultRecordedEvent event) {
        int score = Math.max(0, Math.min(100, (int) Math.round(event.normalizedScore())));
        // F13 : la couverture voyage désormais avec le score. Games la calcule
        // (mini-jeux joués / mini-jeux jouables du module) ; elle était jusqu'ici
        // jetée par ce listener, et le calcul du Fit Score utilisait un 100 figé.
        int coverage = Math.max(0, Math.min(100, event.coverageRatio()));
        String module = event.gameType().name();
        var existingId = projections.findByCandidateIdAndModule(event.playerId(), module)
            .map(SoftSkillsProjection::id).orElse(null);
        projections.save(existingId != null
            ? new SoftSkillsProjection(existingId, event.playerId(), module, score, coverage, event.occurredAt())
            : SoftSkillsProjection.create(event.playerId(), module, score, coverage, event.occurredAt()));
        // Enfilé : plus de plafond de 20, et le travail survit à un redémarrage.
        enqueuer.enqueueUrgent(recompute.pairsForCandidate(event.playerId()).stream()
            .map(pair -> new CandidateOfferPair(pair.candidateId(), pair.offer().id()))
            .toList());
        generateSummary.execute(event.playerId());
    }
}
