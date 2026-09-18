package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartBalloonReport;
import com.zennyt.games.domain.vo.BartMetrics;

import java.util.ArrayList;
import java.util.List;

/**
 * Rejoue chaque ballon contre la séquence serveur et rejette les issues impossibles.
 *
 * <p>Un ballon qui éclate à la pompe {@code e} ne peut être déclaré ni collecté à
 * {@code e} pompes ou plus, ni éclaté à un autre numéro que {@code e}. Une telle
 * déclaration n'est pas une passation invalide (audit-only) : c'est un payload
 * falsifié ou corrompu, refusé avant toute persistance.
 */
public final class BartActionReplayer {

    public List<BartBalloonReport> replay(List<Integer> explosionPoints, BartMetrics metrics) {
        if (explosionPoints.size() != BartConfig.TOTAL_BALLOON_COUNT) {
            throw new IllegalStateException("Séquence BART incomplète");
        }
        List<BartBalloonReport> reports = new ArrayList<>(metrics.balloons().size());
        for (BartBalloonMetric balloon : metrics.balloons()) {
            int explosionPoint = explosionPoints.get(balloon.balloonIndex());
            if (balloon.outcome() == BartBalloonOutcome.EXPLODED
                && balloon.pumpCount() != explosionPoint) {
                throw new IllegalArgumentException("Ballon " + balloon.balloonIndex()
                    + " : éclatement déclaré à la pompe " + balloon.pumpCount()
                    + ", incompatible avec la séquence serveur");
            }
            if (balloon.outcome() == BartBalloonOutcome.COLLECTED
                && balloon.pumpCount() >= explosionPoint) {
                throw new IllegalArgumentException("Ballon " + balloon.balloonIndex()
                    + " : collecte impossible, le ballon aurait éclaté avant");
            }
            int earned = balloon.outcome() == BartBalloonOutcome.COLLECTED
                ? balloon.pumpCount() * BartConfig.POINTS_PER_PUMP : 0;
            reports.add(new BartBalloonReport(balloon.balloonIndex(), balloon.phase(),
                explosionPoint, balloon.pumpCount(), balloon.outcome(), earned));
        }
        return List.copyOf(reports);
    }
}
