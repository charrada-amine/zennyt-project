package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.MemoryQuestConfig;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.List;

/**
 * Service de domaine : barème de « J'investigue » (mémoire de travail).
 *
 * <p>Java pur, sans Spring. Chaque tâche est notée <b>0–5</b> (via
 * {@link MemoryQuestConfig#taskScore(double)}), le composite est la <b>moyenne
 * des tâches jouées, normalisée /100</b>. Le score est <b>calculé serveur</b> —
 * le client n'envoie que des mesures.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : {@code games_mock_repository.dart}
 * ({@code _scoreMemoryQuest}) reproduit ce barème à l'identique.
 */
public class MemoryQuestScoringService {

    /** Score du mini-jeu : composite /100 + interprétation (indicative). */
    public Score score(MemoryQuestMetrics m) {
        int composite = compositeScore(m);
        return new Score(composite, MemoryQuestConfig.COMPOSITE_MAX,
            MemoryQuestConfig.interpret(composite));
    }

    /** Composite = moyenne des notes de tâches jouées, normalisée /100. */
    public int compositeScore(MemoryQuestMetrics m) {
        List<Integer> tasks = new ArrayList<>();
        tasks.add(MemoryQuestConfig.taskScore(m.sameAccuracy()));
        tasks.add(MemoryQuestConfig.taskScore(m.reverseAccuracy()));
        if (m.missionBPlayed()) {
            tasks.add(MemoryQuestConfig.taskScore(m.restoreAccuracy()));
        }
        if (m.distractionPlayed()) {
            tasks.add(MemoryQuestConfig.taskScore(m.afterDistractionAccuracy()));
        }
        double avg = tasks.stream().mapToInt(Integer::intValue).average().orElse(0.0);
        return (int) Math.round(avg / MemoryQuestConfig.TASK_MAX_SCORE * MemoryQuestConfig.COMPOSITE_MAX);
    }

    /** Indicateurs détaillés (notes par tâche + composite) pour la réponse. */
    public MemoryQuestReport report(MemoryQuestMetrics m) {
        return new MemoryQuestReport(
            compositeScore(m),
            MemoryQuestConfig.taskScore(m.sameAccuracy()),
            MemoryQuestConfig.taskScore(m.reverseAccuracy()),
            m.missionBPlayed() ? MemoryQuestConfig.taskScore(m.restoreAccuracy()) : null,
            m.distractionPlayed() ? MemoryQuestConfig.taskScore(m.afterDistractionAccuracy()) : null,
            m.highestSequenceLength(),
            m.distractionQuestionCorrect(),
            m.missionBPlayed(),
            m.distractionPlayed());
    }
}
