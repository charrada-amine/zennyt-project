package com.zennyt.games.support;

import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.service.BartSequenceGenerator;
import com.zennyt.games.domain.service.IstLayoutGenerator;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.IstBoxOpening;
import com.zennyt.games.domain.vo.IstColor;
import com.zennyt.games.domain.vo.IstCondition;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.IstTrialMetric;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Joueurs simulés, joués contre la VRAIE séquence/grille générée pour la session. */
public final class DecisionBehavioralTestFixtures {

    public static final UUID SESSION_ID = UUID.fromString("5b6b3a43-9d2f-4c7e-8a51-0c2e7f1d9a10");

    private DecisionBehavioralTestFixtures() {
    }

    /** Joueur BART à stratégie fixe : pompe {@code target} fois, ou jusqu'à l'éclatement. */
    public static BartMetrics bartFixedStrategy(UUID sessionId, int target, long intervalMs) {
        List<Integer> points = new BartSequenceGenerator().generate(sessionId);
        List<BartBalloonMetric> balloons = new ArrayList<>();
        for (int i = 0; i < BartConfig.TOTAL_BALLOON_COUNT; i++) {
            balloons.add(balloon(i, target, points.get(i), intervalMs));
        }
        return new BartMetrics(BartConfig.PROTOCOL_VERSION, balloons, true, false, 0, 0);
    }

    public static BartBalloonMetric balloon(int index, int target, int explosionPoint, long intervalMs) {
        boolean explodes = target >= explosionPoint;
        int pumps = explodes ? explosionPoint : target;
        List<Long> stamps = new ArrayList<>();
        for (int p = 1; p <= pumps; p++) stamps.add(p * intervalMs);
        return new BartBalloonMetric(index, BartConfig.phaseOf(index), pumps,
            explodes ? BartBalloonOutcome.EXPLODED : BartBalloonOutcome.COLLECTED,
            stamps, explodes ? null : (pumps + 1) * intervalMs);
    }

    /**
     * Joueur IST : ouvre les N premières cases (ordre d'index), puis choisit la
     * couleur majoritaire parmi celles vues (BLEU en cas d'égalité) — ou, si
     * {@code contrarian}, la couleur minoritaire.
     */
    public static IstMetrics istStrategy(UUID sessionId, int boxesFixed, int boxesDecreasing,
                                         Integer confidence, boolean contrarian, long intervalMs) {
        List<IstLayoutGenerator.Layout> layouts = new IstLayoutGenerator().generate(sessionId);
        List<IstTrialMetric> trials = new ArrayList<>();
        for (IstLayoutGenerator.Layout layout : layouts) {
            int n = layout.condition() == IstCondition.FIXED_WIN ? boxesFixed : boxesDecreasing;
            List<IstBoxOpening> openings = new ArrayList<>();
            int blue = 0;
            for (int b = 0; b < n; b++) {
                openings.add(new IstBoxOpening(b, (b + 1) * intervalMs));
                if (layout.boxes().get(b) == IstColor.BLUE) blue++;
            }
            IstColor seenMajority = blue * 2 >= n ? IstColor.BLUE : IstColor.ORANGE;
            IstColor chosen = contrarian
                ? (seenMajority == IstColor.BLUE ? IstColor.ORANGE : IstColor.BLUE)
                : seenMajority;
            trials.add(new IstTrialMetric(layout.trialIndex(), layout.phase(), layout.condition(),
                openings, chosen, (n + 1) * intervalMs, confidence));
        }
        return new IstMetrics(IstConfig.PROTOCOL_VERSION, trials, true, false, 0, 0);
    }
}
