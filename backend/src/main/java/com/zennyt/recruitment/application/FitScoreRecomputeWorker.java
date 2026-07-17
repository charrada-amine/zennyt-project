package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/** Exécute une paire par tâche afin qu'un lot n'attende pas les appels Groq en série. */
@Component
public class FitScoreRecomputeWorker {
    private final RecomputeFitScoresUseCase recompute;

    public FitScoreRecomputeWorker(RecomputeFitScoresUseCase recompute) {
        this.recompute = recompute;
    }

    @Async("recruitmentFitScoreExecutor")
    public void submit(RecomputeFitScoresUseCase.Pair pair) {
        recompute.recompute(pair.candidateId(), pair.offer());
    }
}
