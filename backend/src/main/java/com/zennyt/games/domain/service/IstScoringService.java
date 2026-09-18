package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.IstProvisionalRules;
import com.zennyt.games.domain.vo.IstBoxOpening;
import com.zennyt.games.domain.vo.IstCondition;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.IstPhase;
import com.zennyt.games.domain.vo.IstReport;
import com.zennyt.games.domain.vo.IstTrialMetric;
import com.zennyt.games.domain.vo.IstTrialReport;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static com.zennyt.games.domain.service.DecisionBehavioralStatistics.meanOrZero;
import static com.zennyt.games.domain.service.DecisionBehavioralStatistics.medianOrNull;
import static com.zennyt.games.domain.service.DecisionBehavioralStatistics.round4;

/**
 * Barème et indicateurs de l'IST, calculés serveur depuis les ouvertures brutes.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : miroir mobile dans
 * {@code mobile/lib/features/games/data/decision_behavioral_scoring.dart}.
 */
public final class IstScoringService {

    private final IstLayoutGenerator generator = new IstLayoutGenerator();
    private final IstActionReplayer replayer = new IstActionReplayer();
    private final MetacognitionService metacognition = new MetacognitionService();

    public IstReport report(UUID sessionId, IstMetrics metrics) {
        List<IstTrialReport> trials = replayer.replay(generator.generate(sessionId), metrics);
        List<IstTrialReport> test = trials.stream()
            .filter(t -> t.phase() == IstPhase.TEST).toList();

        int correct = (int) test.stream().filter(IstTrialReport::correct).count();
        double accuracy = test.isEmpty() ? 0.0 : (double) correct / test.size();
        double boxesFixed = meanOrZero(boxes(test, IstCondition.FIXED_WIN));
        double boxesDecreasing = meanOrZero(boxes(test, IstCondition.DECREASING_WIN));
        double pCorrect = meanOrZero(test.stream().map(IstTrialReport::pCorrectAtDecision).toList());
        int earnings = test.stream().mapToInt(IstTrialReport::trialPoints).sum();
        int randomResponses = (int) test.stream()
            .filter(t -> t.pCorrectAtDecision() <= IstProvisionalRules.RANDOM_RESPONSE_MAX_P_CORRECT)
            .count();

        List<Long> intervals = new ArrayList<>();
        for (IstTrialMetric trial : metrics.trials()) {
            if (trial.phase() != IstPhase.TEST) continue;
            long previous = -1L;
            for (IstBoxOpening opening : trial.openings()) {
                if (previous >= 0) intervals.add(opening.timestampMs() - previous);
                previous = opening.timestampMs();
            }
            if (previous >= 0) intervals.add(trial.decisionTimestampMs() - previous);
        }
        Double medianInterval = medianOrNull(intervals);

        List<String> issues = new ArrayList<>();
        if (!metrics.sessionCompleted()) issues.add("INCOMPLETE");
        if (metrics.interrupted()) issues.add("INTERRUPTED");
        if (metrics.backgroundEventCount() > 0) issues.add("BACKGROUND");
        if (metrics.focusLossCount() > 0) issues.add("FOCUS_LOSS");
        if (!test.isEmpty() && test.stream().allMatch(t -> t.boxesOpened() == 0)) {
            issues.add("NON_ENGAGED");
        }
        if (medianInterval != null
            && medianInterval < IstProvisionalRules.MIN_MEDIAN_INTER_ACTION_MS) {
            issues.add("IMPLAUSIBLE_TIMING");
        }
        if (!test.isEmpty()
            && (double) randomResponses / test.size() > IstProvisionalRules.MAX_RANDOM_RESPONSE_RATE) {
            issues.add("RANDOM_RESPONSES");
        }

        MetacognitionService.Calibration calibration = metacognition.calibration(test);
        int score = IstProvisionalRules.score(accuracy, pCorrect, boxesFixed, boxesDecreasing)
            .rawPoints();

        return new IstReport(metrics.protocolVersion(), issues.isEmpty(), issues, test.size(),
            correct, round4(accuracy * 100.0), boxesFixed, boxesDecreasing,
            round4(boxesFixed - boxesDecreasing), pCorrect,
            meanOrZero(pCorrects(test, IstCondition.FIXED_WIN)),
            meanOrZero(pCorrects(test, IstCondition.DECREASING_WIN)),
            earnings, randomResponses, medianInterval,
            calibration.responseCount(), calibration.bias(), score, trials);
    }

    public Score score(IstReport report) {
        return new Score(report.provisionalScore(), IstProvisionalRules.MAX_POINTS,
            IstProvisionalRules.DESCRIPTIVE_LEVEL);
    }

    private static List<Integer> boxes(List<IstTrialReport> trials, IstCondition condition) {
        return trials.stream().filter(t -> t.condition() == condition)
            .map(IstTrialReport::boxesOpened).toList();
    }

    private static List<Double> pCorrects(List<IstTrialReport> trials, IstCondition condition) {
        return trials.stream().filter(t -> t.condition() == condition)
            .map(IstTrialReport::pCorrectAtDecision).toList();
    }
}
