package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.config.ContinuousAttentionProvisionalRules;
import com.zennyt.games.domain.config.ContinuousAttentionProvisionalRules.AccuracyCounts;
import com.zennyt.games.domain.vo.ContinuousAttentionBlockMetric;
import com.zennyt.games.domain.vo.ContinuousAttentionEpochReport;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionPhase;
import com.zennyt.games.domain.vo.ContinuousAttentionPhaseReport;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Scoring et indicateurs descriptifs Long Rosvold.
 *
 * <p>Seules les balanced accuracies X_TEST et AX_TEST entrent dans le /100.
 * Temps de réaction, d-prime et biais c restent strictement descriptifs.
 */
public final class ContinuousAttentionScoringService {

    private final ContinuousAttentionSequenceGenerator generator =
        new ContinuousAttentionSequenceGenerator();

    public ContinuousAttentionReport report(UUID sessionId,
                                            ContinuousAttentionMetrics metrics) {
        generator.validate(sessionId, metrics);

        List<ContinuousAttentionBlockMetric> xBlocks =
            testBlocks(metrics, ContinuousAttentionPhase.X_TEST);
        List<ContinuousAttentionBlockMetric> axBlocks =
            testBlocks(metrics, ContinuousAttentionPhase.AX_TEST);
        ContinuousAttentionPhaseReport x = phaseReport(
            ContinuousAttentionPhase.X_TEST, flatten(xBlocks));
        ContinuousAttentionPhaseReport ax = phaseReport(
            ContinuousAttentionPhase.AX_TEST, flatten(axBlocks));
        Score score = scoreFromCounts(x, ax);

        List<ContinuousAttentionEpochReport> epochs = new ArrayList<>(8);
        epochs.addAll(epochReports(ContinuousAttentionPhase.X_TEST, xBlocks));
        epochs.addAll(epochReports(ContinuousAttentionPhase.AX_TEST, axBlocks));

        PairCounts pairCounts = pairCounts(flatten(axBlocks));
        int extraResponses = metrics.blocks().stream()
            .flatMap(block -> block.trials().stream())
            .mapToInt(ContinuousAttentionTrialMetric::extraResponseCount)
            .sum();
        boolean trialInterrupted = metrics.blocks().stream()
            .flatMap(block -> block.trials().stream())
            .anyMatch(ContinuousAttentionTrialMetric::interrupted);
        boolean interrupted = metrics.interrupted() || trialInterrupted;
        int timingDeviations = timingDeviationCount(metrics);

        List<String> issues = new ArrayList<>();
        if (!metrics.sessionCompleted()) {
            issues.add("SESSION_INCOMPLETE");
        }
        if (interrupted) {
            issues.add("INTERRUPTED");
        }
        if (metrics.backgroundEventCount() > 0) {
            issues.add("BACKGROUND_EVENT");
        }
        if (timingDeviations > 0) {
            issues.add("TIMING_DEVIATION");
        }

        return new ContinuousAttentionReport(
            ContinuousAttentionConfig.PROTOCOL_VERSION,
            metrics.sessionCompleted(),
            issues.isEmpty(),
            interrupted,
            score.rawPoints(),
            x,
            ax,
            epochs,
            pairCounts.ax(),
            pairCounts.ay(),
            pairCounts.bx(),
            pairCounts.by(),
            extraResponses,
            metrics.backgroundEventCount(),
            metrics.droppedFrameCount(),
            timingDeviations,
            issues);
    }

    public Score score(ContinuousAttentionReport report) {
        return scoreFromCounts(report.xPhase(), report.axPhase());
    }

    private static Score scoreFromCounts(
            ContinuousAttentionPhaseReport x,
            ContinuousAttentionPhaseReport ax) {
        return ContinuousAttentionProvisionalRules.score(
            new AccuracyCounts(
                x.hitCount(), x.targetCount(),
                x.correctRejectionCount(), x.nonTargetCount()),
            new AccuracyCounts(
                ax.hitCount(), ax.targetCount(),
                ax.correctRejectionCount(), ax.nonTargetCount()));
    }

    private static List<ContinuousAttentionBlockMetric> testBlocks(
            ContinuousAttentionMetrics metrics, ContinuousAttentionPhase phase) {
        return metrics.blocks().stream()
            .filter(block -> block.phase() == phase)
            .toList();
    }

    private static List<ContinuousAttentionTrialMetric> flatten(
            List<ContinuousAttentionBlockMetric> blocks) {
        return blocks.stream().flatMap(block -> block.trials().stream()).toList();
    }

    private static ContinuousAttentionPhaseReport phaseReport(
            ContinuousAttentionPhase phase,
            List<ContinuousAttentionTrialMetric> trials) {
        Counts counts = counts(phase, trials);
        double hitRate = rate(counts.hits(), counts.targets());
        double omissionRate = rate(counts.omissions(), counts.targets());
        double falseAlarmRate = rate(counts.commissions(), counts.nonTargets());
        double correctRejectionRate =
            rate(counts.correctRejections(), counts.nonTargets());
        double balancedAccuracy = (hitRate + correctRejectionRate) / 2.0;
        Stats stats = stats(counts.hitLatencies());
        SignalDetection signal = signalDetection(
            counts.hits(), counts.targets(),
            counts.commissions(), counts.nonTargets());

        return new ContinuousAttentionPhaseReport(
            phase,
            counts.targets(),
            counts.nonTargets(),
            counts.hits(),
            counts.omissions(),
            counts.commissions(),
            counts.correctRejections(),
            hitRate,
            omissionRate,
            falseAlarmRate,
            correctRejectionRate,
            balancedAccuracy,
            stats.average(),
            stats.median(),
            stats.stdDev(),
            stats.coefficientOfVariation(),
            signal.dPrime(),
            signal.biasC());
    }

    private static List<ContinuousAttentionEpochReport> epochReports(
            ContinuousAttentionPhase phase,
            List<ContinuousAttentionBlockMetric> blocks) {
        List<ContinuousAttentionEpochReport> reports =
            new ArrayList<>(ContinuousAttentionConfig.EPOCH_COUNT_PER_TEST_PHASE);
        for (int epoch = 0;
             epoch < ContinuousAttentionConfig.EPOCH_COUNT_PER_TEST_PHASE;
             epoch++) {
            int from = epoch * ContinuousAttentionConfig.EPOCH_BLOCK_COUNT;
            int to = from + ContinuousAttentionConfig.EPOCH_BLOCK_COUNT;
            Counts counts = counts(phase, flatten(blocks.subList(from, to)));
            Stats stats = stats(counts.hitLatencies());
            SignalDetection signal = signalDetection(
                counts.hits(), counts.targets(),
                counts.commissions(), counts.nonTargets());
            reports.add(new ContinuousAttentionEpochReport(
                phase,
                epoch + 1,
                rate(counts.hits(), counts.targets()),
                rate(counts.commissions(), counts.nonTargets()),
                stats.average(),
                stats.stdDev(),
                signal.dPrime()));
        }
        return List.copyOf(reports);
    }

    private static Counts counts(ContinuousAttentionPhase phase,
                                 List<ContinuousAttentionTrialMetric> trials) {
        int targets = 0;
        int nonTargets = 0;
        int hits = 0;
        int omissions = 0;
        int commissions = 0;
        int correctRejections = 0;
        List<Integer> latencies = new ArrayList<>();
        for (ContinuousAttentionTrialMetric trial : trials) {
            boolean target = ContinuousAttentionMetrics.isTarget(
                phase, trial.previousLetter(), trial.currentLetter());
            if (target) {
                targets++;
                if (trial.responded()) {
                    hits++;
                    latencies.add(trial.latencyMs());
                } else {
                    omissions++;
                }
            } else {
                nonTargets++;
                if (trial.responded()) {
                    commissions++;
                } else {
                    correctRejections++;
                }
            }
        }
        return new Counts(targets, nonTargets, hits, omissions,
            commissions, correctRejections, List.copyOf(latencies));
    }

    private static PairCounts pairCounts(
            List<ContinuousAttentionTrialMetric> axTrials) {
        int ax = 0;
        int ay = 0;
        int bx = 0;
        int by = 0;
        for (ContinuousAttentionTrialMetric trial : axTrials) {
            boolean previousA = "A".equals(trial.previousLetter());
            boolean currentX = "X".equals(trial.currentLetter());
            if (previousA && currentX) {
                ax++;
            } else if (previousA) {
                ay++;
            } else if (currentX) {
                bx++;
            } else {
                by++;
            }
        }
        return new PairCounts(ax, ay, bx, by);
    }

    private static int timingDeviationCount(ContinuousAttentionMetrics metrics) {
        int deviations = 0;
        for (ContinuousAttentionBlockMetric block : metrics.blocks()) {
            for (ContinuousAttentionTrialMetric trial : block.trials()) {
                boolean deviates =
                    Math.abs(trial.actualDisplayDurationMs()
                        - ContinuousAttentionConfig.LETTER_DISPLAY_MS)
                        > ContinuousAttentionConfig.TIMING_TOLERANCE_MS
                    || Math.abs(trial.actualIsiDurationMs()
                        - ContinuousAttentionConfig.ISI_MS)
                        > ContinuousAttentionConfig.TIMING_TOLERANCE_MS
                    || Math.abs(trial.actualOnsetMs() - trial.scheduledOnsetMs())
                        > ContinuousAttentionConfig.TIMING_TOLERANCE_MS;
                if (deviates) {
                    deviations++;
                }
            }
        }
        return deviations;
    }

    private static double rate(int numerator, int denominator) {
        return denominator == 0 ? 0.0 : numerator * 100.0 / denominator;
    }

    private static Stats stats(List<Integer> values) {
        if (values.isEmpty()) {
            return new Stats(null, null, null, null);
        }
        double average = values.stream().mapToInt(Integer::intValue).average().orElse(0);
        List<Integer> sorted = values.stream().sorted(Comparator.naturalOrder()).toList();
        int middle = sorted.size() / 2;
        double median = sorted.size() % 2 == 0
            ? (sorted.get(middle - 1) + sorted.get(middle)) / 2.0
            : sorted.get(middle);
        double variance = values.stream()
            .mapToDouble(value -> {
                double delta = value - average;
                return delta * delta;
            })
            .average()
            .orElse(0);
        double stdDev = Math.sqrt(variance);
        Double coefficient = average == 0 ? null : stdDev / average;
        return new Stats(average, median, stdDev, coefficient);
    }

    private static SignalDetection signalDetection(
            int hits, int targets, int falseAlarms, int nonTargets) {
        double correctedHitRate = (hits + 0.5) / (targets + 1.0);
        double correctedFalseAlarmRate =
            (falseAlarms + 0.5) / (nonTargets + 1.0);
        double zHit = inverseStandardNormal(correctedHitRate);
        double zFalseAlarm = inverseStandardNormal(correctedFalseAlarmRate);
        return new SignalDetection(
            zHit - zFalseAlarm,
            -0.5 * (zHit + zFalseAlarm));
    }

    /**
     * Approximation rationnelle d'Acklam de l'inverse de la loi normale
     * standard. Les taux log-linéaires sont toujours strictement dans ]0,1[.
     */
    static double inverseStandardNormal(double probability) {
        if (probability <= 0 || probability >= 1) {
            throw new IllegalArgumentException("probability doit appartenir à ]0,1[");
        }
        double[] a = {
            -3.969683028665376e+01, 2.209460984245205e+02,
            -2.759285104469687e+02, 1.383577518672690e+02,
            -3.066479806614716e+01, 2.506628277459239e+00
        };
        double[] b = {
            -5.447609879822406e+01, 1.615858368580409e+02,
            -1.556989798598866e+02, 6.680131188771972e+01,
            -1.328068155288572e+01
        };
        double[] c = {
            -7.784894002430293e-03, -3.223964580411365e-01,
            -2.400758277161838e+00, -2.549732539343734e+00,
            4.374664141464968e+00, 2.938163982698783e+00
        };
        double[] d = {
            7.784695709041462e-03, 3.224671290700398e-01,
            2.445134137142996e+00, 3.754408661907416e+00
        };
        double lower = 0.02425;
        double upper = 1 - lower;
        if (probability < lower) {
            double q = Math.sqrt(-2 * Math.log(probability));
            return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
                / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
        }
        if (probability > upper) {
            double q = Math.sqrt(-2 * Math.log(1 - probability));
            return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
                / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
        }
        double q = probability - 0.5;
        double r = q * q;
        return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5])
            * q / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
    }

    private record Counts(
        int targets,
        int nonTargets,
        int hits,
        int omissions,
        int commissions,
        int correctRejections,
        List<Integer> hitLatencies
    ) {
    }

    private record Stats(
        Double average,
        Double median,
        Double stdDev,
        Double coefficientOfVariation
    ) {
    }

    private record SignalDetection(double dPrime, double biasC) {
    }

    private record PairCounts(int ax, int ay, int bx, int by) {
    }
}
