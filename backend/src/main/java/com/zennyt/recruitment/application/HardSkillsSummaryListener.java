package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.application.usecase.GenerateHardSkillsSummaryUseCase;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Régénère le résumé IA "Hard Skills Summary" à chaque résultat de test complété. */
@Component
public class HardSkillsSummaryListener {
    private final GenerateHardSkillsSummaryUseCase generateSummary;

    public HardSkillsSummaryListener(GenerateHardSkillsSummaryUseCase generateSummary) {
        this.generateSummary = generateSummary;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(TestResultCompletedEvent event) {
        generateSummary.execute(event.testResultId());
    }
}
