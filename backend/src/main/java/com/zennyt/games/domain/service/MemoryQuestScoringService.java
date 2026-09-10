package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.MemoryQuestConfig;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.MemoryTaskResult;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.List;

/**
 * Service de domaine : barème de « J'investigue » (mémoire de travail).
 *
 * <p>Java pur, sans Spring. Chaque tâche est notée <b>0–5</b> (via
 * {@link MemoryQuestConfig#taskScore(double)}), le composite est la <b>moyenne
 * des tâches jouées, normalisée /100</b> (invariant conservé). Le score est
 * <b>calculé serveur</b> — le client n'envoie que des mesures.
 *
 * <p><b>Le calibrage appareil affecte le score via le TIMEOUT</b> (Memory Quest
 * est le premier module dont le score dépend du temps) : une tâche dont le temps
 * dépasse {@code max_task_time_ms + offset} est un échec par dépassement (note
 * voidée) ; l'offset remonte le seuil pour ne pas pénaliser un appareil lent. La
 * justesse du rappel elle-même reste inchangée.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : {@code games_mock_repository.dart}
 * ({@code _scoreMemoryQuest}) reproduit ce barème à l'identique.
 */
public class MemoryQuestScoringService {

    /** Score du mini-jeu, sans calibrage (offset 0). Compatibilité. */
    public Score score(MemoryQuestMetrics m) {
        return score(m, 0.0);
    }

    /** Score du mini-jeu : composite /100 + interprétation, timeout ajusté du calibrage. */
    public Score score(MemoryQuestMetrics m, double calibrationOffsetMs) {
        int composite = compositeScore(m, calibrationOffsetMs);
        return new Score(composite, MemoryQuestConfig.COMPOSITE_MAX,
            MemoryQuestConfig.interpret(composite));
    }

    /** Composite sans calibrage (offset 0). Compatibilité. */
    public int compositeScore(MemoryQuestMetrics m) {
        return compositeScore(m, 0.0);
    }

    /**
     * Composite = moyenne des notes de tâches jouées, normalisée /100.
     *
     * <p>Avec timings par tâche : chaque tâche dépassant le timeout ajusté est
     * <b>voidée</b> (note 0) ; sinon note de rappel. Sans timings : agrégats plats
     * (comportement historique inchangé — composite identique à l'ancien).
     */
    public int compositeScore(MemoryQuestMetrics m, double calibrationOffsetMs) {
        List<Integer> tasks = new ArrayList<>();
        if (m.hasTaskTimings()) {
            for (MemoryTaskResult t : m.tasks()) {
                // Le délai applicable dépend du TYPE : une tâche parasite est
                // jugée sur le budget de son niveau.
                boolean timedOut = MemoryQuestMetrics.isTimedOut(t, calibrationOffsetMs);
                tasks.add(timedOut ? 0 : MemoryQuestConfig.taskScore(t.accuracy()));
            }
        } else {
            // Repli sur les agrégats plats : seules les tâches que le MODE a
            // réellement fait jouer sont notées. Une partie d'images n'a ni
            // rappel direct ni rappel inverse — les compter à 0 écraserait le
            // composite.
            if (m.mode().playsDigits()) {
                tasks.add(MemoryQuestConfig.taskScore(m.sameAccuracy()));
                tasks.add(MemoryQuestConfig.taskScore(m.reverseAccuracy()));
            }
            if (m.missionBPlayed()) {
                tasks.add(MemoryQuestConfig.taskScore(m.restoreAccuracy()));
            }
            if (m.distractionPlayed()) {
                tasks.add(MemoryQuestConfig.taskScore(m.afterDistractionAccuracy()));
            }
            if (m.distractionChallengesPlayed() > 0) {
                tasks.add(MemoryQuestConfig.taskScore(m.distractionSolveRate()));
            }
        }
        double avg = tasks.stream().mapToInt(Integer::intValue).average().orElse(0.0);
        return (int) Math.round(avg / MemoryQuestConfig.TASK_MAX_SCORE * MemoryQuestConfig.COMPOSITE_MAX);
    }

    /** Indicateurs (notes par tâche + composite + niveau + validité) — sans calibrage. */
    public MemoryQuestReport report(MemoryQuestMetrics m) {
        return report(m, 0.0);
    }

    /** Indicateurs détaillés, timeout/validité ajustés du calibrage. */
    public MemoryQuestReport report(MemoryQuestMetrics m, double calibrationOffsetMs) {
        int timeouts = m.timeoutTaskCount(calibrationOffsetMs);
        boolean valid = MemoryQuestConfig.isSessionValid(
            calibrationOffsetMs, m.sessionCompleted(), timeouts);
        // Les notes de rappel de chiffres sont NULLES quand le mode ne les joue
        // pas : les publier à 0 laisserait croire à un échec sur une épreuve qui
        // n'a jamais eu lieu.
        boolean digits = m.mode().playsDigits();
        return new MemoryQuestReport(
            compositeScore(m, calibrationOffsetMs),
            digits ? MemoryQuestConfig.taskScore(m.sameAccuracy()) : null,
            digits ? MemoryQuestConfig.taskScore(m.reverseAccuracy()) : null,
            m.missionBPlayed() ? MemoryQuestConfig.taskScore(m.restoreAccuracy()) : null,
            m.distractionPlayed() ? MemoryQuestConfig.taskScore(m.afterDistractionAccuracy()) : null,
            m.distractionChallengesPlayed() > 0
                ? MemoryQuestConfig.taskScore(m.distractionSolveRate()) : null,
            m.highestSequenceLength(),
            m.distractionQuestionCorrect(),
            m.missionBPlayed(),
            m.distractionPlayed(),
            m.distractionChallengesPlayed(),
            m.distractionChallengesSolved(),
            m.distractionTimeouts(),
            m.mode(),
            m.finalLevel(),
            valid,
            timeouts);
    }
}
