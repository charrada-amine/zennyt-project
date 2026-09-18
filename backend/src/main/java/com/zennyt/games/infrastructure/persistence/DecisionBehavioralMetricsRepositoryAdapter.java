package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.DecisionBehavioralMetricsRepository;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonReport;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.BartReport;
import com.zennyt.games.domain.vo.IstBoxOpening;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.IstReport;
import com.zennyt.games.domain.vo.IstTrialMetric;
import com.zennyt.games.domain.vo.IstTrialReport;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Persistance JDBC des traces brutes et indicateurs serveur de BART et IST (V84). */
@Component
public class DecisionBehavioralMetricsRepositoryAdapter
        implements DecisionBehavioralMetricsRepository {

    static final String DELETE_BART_RUN_SQL =
        "DELETE FROM games.bart_runs WHERE session_id = ?";
    static final String INSERT_BART_RUN_SQL = """
        INSERT INTO games.bart_runs (
            session_id, protocol_version, session_completed, interrupted,
            background_event_count, focus_loss_count, session_valid, validity_issues,
            test_balloon_count, collected_count, explosion_count,
            adjusted_average_pumps, total_earnings, ev_optimal_earnings,
            optimal_fixed_pumps, efficiency_percent, mean_pumps_after_explosion,
            mean_pumps_after_collect, median_inter_pump_interval_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_BART_BALLOON_SQL = """
        INSERT INTO games.bart_balloons (
            session_id, balloon_index, phase, explosion_point, pump_count,
            outcome, earned_points, collect_timestamp_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_BART_PUMP_SQL = """
        INSERT INTO games.bart_pumps (session_id, balloon_index, pump_index, timestamp_ms)
        VALUES (?, ?, ?, ?)
        """;

    static final String DELETE_IST_RUN_SQL =
        "DELETE FROM games.ist_runs WHERE session_id = ?";
    static final String INSERT_IST_RUN_SQL = """
        INSERT INTO games.ist_runs (
            session_id, protocol_version, session_completed, interrupted,
            background_event_count, focus_loss_count, session_valid, validity_issues,
            test_trial_count, correct_count, accuracy_percent, mean_boxes_fixed_win,
            mean_boxes_decreasing_win, condition_discrimination,
            mean_p_correct_at_decision, mean_p_correct_fixed_win,
            mean_p_correct_decreasing_win, total_earnings, random_response_count,
            median_inter_action_interval_ms, confidence_response_count,
            calibration_bias, provisional_score
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_IST_TRIAL_SQL = """
        INSERT INTO games.ist_trials (
            session_id, trial_index, phase, condition, majority_color, chosen_color,
            correct, boxes_opened, blue_seen, orange_seen, p_correct_at_decision,
            trial_points, decision_timestamp_ms, confidence
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_IST_OPENING_SQL = """
        INSERT INTO games.ist_box_openings (
            session_id, trial_index, opening_index, box_index, timestamp_ms
        ) VALUES (?, ?, ?, ?, ?)
        """;

    private final JdbcTemplate jdbc;

    public DecisionBehavioralMetricsRepositoryAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void replaceBart(UUID sessionId, BartMetrics metrics, BartReport report) {
        jdbc.update(DELETE_BART_RUN_SQL, sessionId);
        jdbc.update(INSERT_BART_RUN_SQL,
            sessionId, metrics.protocolVersion(), metrics.sessionCompleted(),
            metrics.interrupted(), metrics.backgroundEventCount(), metrics.focusLossCount(),
            report.sessionValid(), String.join(",", report.validityIssues()),
            report.testBalloonCount(), report.collectedCount(), report.explosionCount(),
            report.adjustedAveragePumps(), report.totalEarnings(), report.evOptimalEarnings(),
            report.optimalFixedPumps(), report.efficiencyPercent(),
            report.meanPumpsAfterExplosion(), report.meanPumpsAfterCollect(),
            report.medianInterPumpIntervalMs());

        List<Object[]> balloons = new ArrayList<>();
        List<Object[]> pumps = new ArrayList<>();
        for (int i = 0; i < report.balloons().size(); i++) {
            BartBalloonReport replayed = report.balloons().get(i);
            BartBalloonMetric raw = metrics.balloons().get(i);
            balloons.add(new Object[] {
                sessionId, replayed.balloonIndex(), replayed.phase().name(),
                replayed.explosionPoint(), replayed.pumpCount(), replayed.outcome().name(),
                replayed.earnedPoints(), raw.collectTimestampMs()});
            for (int p = 0; p < raw.pumpTimestampsMs().size(); p++) {
                pumps.add(new Object[] {
                    sessionId, raw.balloonIndex(), p + 1, raw.pumpTimestampsMs().get(p)});
            }
        }
        jdbc.batchUpdate(INSERT_BART_BALLOON_SQL, balloons);
        if (!pumps.isEmpty()) jdbc.batchUpdate(INSERT_BART_PUMP_SQL, pumps);
    }

    @Override
    public void replaceIst(UUID sessionId, IstMetrics metrics, IstReport report) {
        jdbc.update(DELETE_IST_RUN_SQL, sessionId);
        jdbc.update(INSERT_IST_RUN_SQL,
            sessionId, metrics.protocolVersion(), metrics.sessionCompleted(),
            metrics.interrupted(), metrics.backgroundEventCount(), metrics.focusLossCount(),
            report.sessionValid(), String.join(",", report.validityIssues()),
            report.testTrialCount(), report.correctCount(), report.accuracyPercent(),
            report.meanBoxesFixedWin(), report.meanBoxesDecreasingWin(),
            report.conditionDiscrimination(), report.meanPCorrectAtDecision(),
            report.meanPCorrectFixedWin(), report.meanPCorrectDecreasingWin(),
            report.totalEarnings(), report.randomResponseCount(),
            report.medianInterActionIntervalMs(), report.confidenceResponseCount(),
            report.calibrationBias(), report.provisionalScore());

        List<Object[]> trials = new ArrayList<>();
        List<Object[]> openings = new ArrayList<>();
        for (int i = 0; i < report.trials().size(); i++) {
            IstTrialReport replayed = report.trials().get(i);
            IstTrialMetric raw = metrics.trials().get(i);
            trials.add(new Object[] {
                sessionId, replayed.trialIndex(), replayed.phase().name(),
                replayed.condition().name(), replayed.majorityColor().name(),
                replayed.chosenColor().name(), replayed.correct(), replayed.boxesOpened(),
                replayed.blueSeen(), replayed.orangeSeen(), replayed.pCorrectAtDecision(),
                replayed.trialPoints(), replayed.decisionTimestampMs(), replayed.confidence()});
            for (int o = 0; o < raw.openings().size(); o++) {
                IstBoxOpening opening = raw.openings().get(o);
                openings.add(new Object[] {
                    sessionId, raw.trialIndex(), o + 1, opening.boxIndex(), opening.timestampMs()});
            }
        }
        jdbc.batchUpdate(INSERT_IST_TRIAL_SQL, trials);
        if (!openings.isEmpty()) jdbc.batchUpdate(INSERT_IST_OPENING_SQL, openings);
    }
}
