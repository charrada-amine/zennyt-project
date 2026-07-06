package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.MoveFastConfig;

import java.util.List;
import java.util.function.Predicate;

/**
 * Indicateurs dérivés de flexibilité cognitive pour « Je bouge / Move Fast »
 * (fiche « JE BOUGE », Tableau 3 — Performance).
 *
 * <p><b>Calculés côté serveur</b> à partir des essais notés (échauffement exclu).
 * Le score Move Fast ne dépend PAS du temps de réaction ; le calibrage appareil
 * n'affecte donc que les indicateurs comportementaux, exposés en deux versions :
 * brute et <b>corrigée</b> ({@code *Adjusted}) — temps brut moins l'offset de
 * calibrage ({@link com.zennyt.games.domain.service.CalibrationService}).
 */
public record MoveFastFlexibilityReport(
    double precisionRatio,
    double averageReactionTimeMs,
    double medianReactionTimeMs,
    double stdDevReactionTimeMs,
    double fastResponsesPercent,
    double slowResponsesPercent,
    double switchResponseTimeAvgMs,
    double nonSwitchResponseTimeAvgMs,
    double switchCostMs,
    int perseverativeErrorsCount,
    int correctResponsesRuleOrientation,
    int correctResponsesRuleMovement,
    int sessionDurationSec,
    String sessionCompletionStatus,
    boolean calibrationApplied,
    boolean calibrationReliable,
    double calibrationOffsetMs,
    double averageReactionTimeAdjustedMs,
    double medianReactionTimeAdjustedMs,
    double fastResponsesPercentAdjusted,
    double slowResponsesPercentAdjusted,
    double switchCostAdjustedMs
) {

    /** Sans calibrage : les indicateurs corrigés valent les bruts (offset 0). */
    public static MoveFastFlexibilityReport from(MoveFastMetrics metrics,
                                                 int sessionDurationSec,
                                                 String sessionCompletionStatus) {
        return from(metrics, sessionDurationSec, sessionCompletionStatus, 0.0, false, true);
    }

    /**
     * Dérive les indicateurs bruts ET corrigés.
     *
     * @param calibrationOffsetMs  offset technique à retrancher des temps bruts (0 si aucun)
     * @param calibrationApplied   true si un calibrage a été fourni
     * @param calibrationReliable  false si calibrage en fallback (fiabilité réduite)
     */
    public static MoveFastFlexibilityReport from(MoveFastMetrics metrics,
                                                 int sessionDurationSec,
                                                 String sessionCompletionStatus,
                                                 double calibrationOffsetMs,
                                                 boolean calibrationApplied,
                                                 boolean calibrationReliable) {
        List<MoveFastResponse> scored = metrics.scoredResponses();
        int total = scored.size();

        long correct = scored.stream().filter(MoveFastResponse::correct).count();

        List<Double> raw = scored.stream()
            .map(r -> (double) r.reactionTimeMs()).toList();
        List<Double> adjusted = scored.stream()
            .map(r -> Math.max(0.0, r.reactionTimeMs() - calibrationOffsetMs)).toList();

        double avg = mean(raw);
        double std = stdDev(raw, avg);

        List<Double> switchRaw = timesWhere(scored, MoveFastResponse::isSwitchTrial, calibrationOffsetMs, false);
        List<Double> nonSwitchRaw = timesWhere(scored, r -> !r.isSwitchTrial(), calibrationOffsetMs, false);
        double switchAvg = mean(switchRaw);
        double nonSwitchAvg = mean(nonSwitchRaw);

        List<Double> switchAdj = timesWhere(scored, MoveFastResponse::isSwitchTrial, calibrationOffsetMs, true);
        List<Double> nonSwitchAdj = timesWhere(scored, r -> !r.isSwitchTrial(), calibrationOffsetMs, true);

        int perseverative = (int) scored.stream().filter(MoveFastResponse::appliedOldRule).count();
        int correctOrientation = (int) scored.stream()
            .filter(r -> r.correct() && r.ruleActive() == MoveFastRule.ORIENTATION).count();
        int correctMovement = (int) scored.stream()
            .filter(r -> r.correct() && r.ruleActive() == MoveFastRule.MOVEMENT).count();

        return new MoveFastFlexibilityReport(
            total == 0 ? 0.0 : correct * 100.0 / total,
            avg, median(raw), std,
            percentBelow(raw, MoveFastConfig.MIN_RESPONSE_TIME_MS),
            percentAbove(raw, MoveFastConfig.MAX_RESPONSE_TIME_MS),
            switchAvg, nonSwitchAvg, switchAvg - nonSwitchAvg,
            perseverative, correctOrientation, correctMovement,
            sessionDurationSec, sessionCompletionStatus,
            calibrationApplied, calibrationReliable, calibrationOffsetMs,
            mean(adjusted), median(adjusted),
            percentBelow(adjusted, MoveFastConfig.MIN_RESPONSE_TIME_MS),
            percentAbove(adjusted, MoveFastConfig.MAX_RESPONSE_TIME_MS),
            mean(switchAdj) - mean(nonSwitchAdj));
    }

    private static List<Double> timesWhere(List<MoveFastResponse> scored,
                                           Predicate<MoveFastResponse> predicate,
                                           double offset, boolean adjusted) {
        return scored.stream()
            .filter(predicate)
            .map(r -> adjusted ? Math.max(0.0, r.reactionTimeMs() - offset) : (double) r.reactionTimeMs())
            .toList();
    }

    private static double mean(List<Double> values) {
        return values.isEmpty() ? 0.0 : values.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
    }

    private static double median(List<Double> values) {
        if (values.isEmpty()) {
            return 0.0;
        }
        List<Double> sorted = values.stream().sorted().toList();
        int n = sorted.size();
        if (n % 2 == 1) {
            return sorted.get(n / 2);
        }
        return (sorted.get(n / 2 - 1) + sorted.get(n / 2)) / 2.0;
    }

    private static double stdDev(List<Double> values, double mean) {
        if (values.size() < 2) {
            return 0.0;
        }
        double variance = values.stream()
            .mapToDouble(v -> (v - mean) * (v - mean))
            .sum() / values.size();
        return Math.sqrt(variance);
    }

    private static double percentBelow(List<Double> values, double threshold) {
        return percent(values, v -> v < threshold);
    }

    private static double percentAbove(List<Double> values, double threshold) {
        return percent(values, v -> v > threshold);
    }

    private static double percent(List<Double> values, Predicate<Double> predicate) {
        if (values.isEmpty()) {
            return 0.0;
        }
        long count = values.stream().filter(predicate).count();
        return count * 100.0 / values.size();
    }
}
