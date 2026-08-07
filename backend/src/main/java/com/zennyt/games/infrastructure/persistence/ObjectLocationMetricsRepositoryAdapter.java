package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationLevelReport;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPlacementAction;
import com.zennyt.games.domain.vo.ObjectLocationReport;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Persistance JDBC des actions brutes et indicateurs serveur de « Je place ». */
@Component
public class ObjectLocationMetricsRepositoryAdapter
        implements ObjectLocationMetricsRepository {

    static final String DELETE_RUN_SQL =
        "DELETE FROM games.object_location_runs WHERE session_id = ?";
    static final String INSERT_RUN_SQL = """
        INSERT INTO games.object_location_runs (
            session_id, protocol_version, completion_reason, session_completed,
            interrupted, background_event_count, focus_loss_count,
            orientation_change_count, dropped_frame_count, session_valid,
            technical_valid, minimum_levels_valid, progression_valid,
            timing_valid, provisional_accuracy_score, completed_level_count,
            passed_level_count, administered_object_count,
            exact_placement_count, swap_count, local_error_count,
            global_error_count, unplaced_count, exact_accuracy_percent,
            swap_rate_percent, local_error_rate_percent,
            global_error_rate_percent, average_displacement_cells, span,
            load_slope, average_first_placement_interval_ms,
            reposition_count, timing_deviation_count, validity_issues
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_LEVEL_SQL = """
        INSERT INTO games.object_location_levels (
            session_id, level_index, phase, object_count,
            actual_encoding_duration_ms, actual_retention_duration_ms,
            actual_recall_duration_ms, timed_out, completed, passed,
            exact_count, swap_count, local_error_count, global_error_count,
            unplaced_count, exact_accuracy_percent,
            average_displacement_cells, action_count, reposition_count,
            average_first_placement_interval_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_ACTION_SQL = """
        INSERT INTO games.object_location_actions (
            session_id, level_index, action_index, action_type, object_id,
            target_cell_index, timestamp_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """;

    private final JdbcTemplate jdbc;

    public ObjectLocationMetricsRepositoryAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void replace(UUID sessionId,
                        ObjectLocationMetrics metrics,
                        ObjectLocationReport report) {
        jdbc.update(DELETE_RUN_SQL, sessionId);
        jdbc.update(INSERT_RUN_SQL,
            sessionId,
            metrics.protocolVersion(),
            metrics.completionReason().name(),
            metrics.sessionCompleted(),
            metrics.interrupted(),
            metrics.backgroundEventCount(),
            metrics.focusLossCount(),
            metrics.orientationChangeCount(),
            metrics.droppedFrameCount(),
            report.sessionValid(),
            report.technicalValid(),
            report.minimumLevelsValid(),
            report.progressionValid(),
            report.timingValid(),
            report.provisionalAccuracyScore(),
            report.completedLevelCount(),
            report.passedLevelCount(),
            report.administeredObjectCount(),
            report.exactPlacementCount(),
            report.swapCount(),
            report.localErrorCount(),
            report.globalErrorCount(),
            report.unplacedCount(),
            report.exactAccuracyPercent(),
            report.swapRatePercent(),
            report.localErrorRatePercent(),
            report.globalErrorRatePercent(),
            report.averageDisplacementCells(),
            report.span(),
            report.loadSlope(),
            report.averageFirstPlacementIntervalMs(),
            report.repositionCount(),
            report.timingDeviationCount(),
            String.join(",", report.validityIssues()));

        List<Object[]> levels = new ArrayList<>(metrics.levels().size());
        List<Object[]> actions = new ArrayList<>();
        for (int i = 0; i < metrics.levels().size(); i++) {
            ObjectLocationLevelMetric metric = metrics.levels().get(i);
            ObjectLocationLevelReport levelReport = report.levels().get(i);
            levels.add(new Object[] {
                sessionId,
                metric.levelIndex(),
                metric.phase().name(),
                metric.objectCount(),
                metric.actualEncodingDurationMs(),
                metric.actualRetentionDurationMs(),
                metric.actualRecallDurationMs(),
                metric.timedOut(),
                metric.completed(),
                levelReport.passed(),
                levelReport.exactCount(),
                levelReport.swapCount(),
                levelReport.localErrorCount(),
                levelReport.globalErrorCount(),
                levelReport.unplacedCount(),
                levelReport.exactAccuracyPercent(),
                levelReport.averageDisplacementCells(),
                metric.actions().size(),
                levelReport.repositionCount(),
                levelReport.averageFirstPlacementIntervalMs()
            });
            for (ObjectLocationPlacementAction action : metric.actions()) {
                actions.add(new Object[] {
                    sessionId,
                    metric.levelIndex(),
                    action.actionIndex(),
                    action.actionType().name(),
                    action.objectId(),
                    action.targetCellIndex(),
                    action.timestampMs()
                });
            }
        }
        jdbc.batchUpdate(INSERT_LEVEL_SQL, levels);
        if (!actions.isEmpty()) jdbc.batchUpdate(INSERT_ACTION_SQL, actions);
    }
}
