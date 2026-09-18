package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.config.BartProvisionalRules;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartBalloonReport;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.BartPhase;
import com.zennyt.games.domain.vo.BartReport;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static com.zennyt.games.domain.service.DecisionBehavioralStatistics.meanOrNull;
import static com.zennyt.games.domain.service.DecisionBehavioralStatistics.medianOrNull;

/**
 * Barème et indicateurs du BART, calculés serveur depuis les pompes brutes.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : miroir mobile dans
 * {@code mobile/lib/features/games/data/decision_behavioral_scoring.dart}. Toute
 * modification ici impose la même modification là-bas, dans la même PR.
 */
public final class BartScoringService {

    private final BartSequenceGenerator generator = new BartSequenceGenerator();
    private final BartActionReplayer replayer = new BartActionReplayer();

    public BartReport report(UUID sessionId, BartMetrics metrics) {
        List<BartBalloonReport> balloons = replayer.replay(generator.generate(sessionId), metrics);
        List<BartBalloonReport> test = balloons.stream()
            .filter(b -> b.phase() == BartPhase.TEST).toList();

        List<Integer> collectedPumps = new ArrayList<>();
        int totalEarnings = 0;
        int explosions = 0;
        for (BartBalloonReport balloon : test) {
            totalEarnings += balloon.earnedPoints();
            if (balloon.outcome() == BartBalloonOutcome.COLLECTED) {
                collectedPumps.add(balloon.pumpCount());
            } else {
                explosions++;
            }
        }

        // Benchmark : la stratégie fixe optimale, jouée sur les MÊMES ballons que le
        // joueur. Elle subit exactement la même chance ; elle n'est pas clairvoyante.
        int optimalPumps = BartConfig.optimalFixedPumps();
        int evOptimal = 0;
        for (BartBalloonReport balloon : test) {
            if (balloon.explosionPoint() > optimalPumps) {
                evOptimal += optimalPumps * BartConfig.POINTS_PER_PUMP;
            }
        }

        List<Integer> afterExplosion = new ArrayList<>();
        List<Integer> afterCollect = new ArrayList<>();
        for (int i = 0; i + 1 < test.size(); i++) {
            int nextPumps = test.get(i + 1).pumpCount();
            if (test.get(i).outcome() == BartBalloonOutcome.EXPLODED) {
                afterExplosion.add(nextPumps);
            } else {
                afterCollect.add(nextPumps);
            }
        }

        List<Long> interPumpIntervals = new ArrayList<>();
        for (BartBalloonMetric balloon : metrics.testBalloons()) {
            List<Long> stamps = balloon.pumpTimestampsMs();
            for (int i = 1; i < stamps.size(); i++) {
                interPumpIntervals.add(stamps.get(i) - stamps.get(i - 1));
            }
        }
        Double medianInterval = medianOrNull(interPumpIntervals);

        List<String> issues = new ArrayList<>();
        if (!metrics.sessionCompleted()) issues.add("INCOMPLETE");
        if (metrics.interrupted()) issues.add("INTERRUPTED");
        if (metrics.backgroundEventCount() > 0) issues.add("BACKGROUND");
        if (metrics.focusLossCount() > 0) issues.add("FOCUS_LOSS");
        if (!test.isEmpty() && test.stream().allMatch(
                b -> b.pumpCount() <= BartProvisionalRules.NON_ENGAGED_MAX_PUMPS)) {
            issues.add("NON_ENGAGED");
        }
        if (medianInterval != null
            && medianInterval < BartProvisionalRules.MIN_MEDIAN_INTER_PUMP_MS) {
            issues.add("IMPLAUSIBLE_TIMING");
        }
        if (evOptimal == 0) issues.add("DEGENERATE_SEQUENCE");

        int efficiency = evOptimal == 0 ? 0
            : BartProvisionalRules.score(totalEarnings, evOptimal).rawPoints();

        return new BartReport(metrics.protocolVersion(), issues.isEmpty(), issues,
            test.size(), collectedPumps.size(), explosions, meanOrNull(collectedPumps),
            totalEarnings, evOptimal, optimalPumps, efficiency,
            meanOrNull(afterExplosion), meanOrNull(afterCollect), medianInterval, balloons);
    }

    /** Score /100 = efficience ; un benchmark nul ne produit aucun point. */
    public Score score(BartReport report) {
        return new Score(report.efficiencyPercent(), BartProvisionalRules.MAX_POINTS,
            BartProvisionalRules.DESCRIPTIVE_LEVEL);
    }
}
