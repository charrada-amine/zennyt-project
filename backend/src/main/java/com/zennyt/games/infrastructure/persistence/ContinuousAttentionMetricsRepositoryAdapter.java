package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.vo.ContinuousAttentionBlockMetric;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Persistance JDBC compacte des 1 364 essais. Le remplacement est transactionnel
 * car il est toujours appelé depuis SubmitGameResultUseCase.
 */
@Component
public class ContinuousAttentionMetricsRepositoryAdapter
        implements ContinuousAttentionMetricsRepository {

    static final String DELETE_RUN_SQL =
        "DELETE FROM games.continuous_attention_runs WHERE session_id = ?";
    static final String INSERT_RUN_SQL = """
        INSERT INTO games.continuous_attention_runs (
            session_id, protocol_version, session_completed, interrupted,
            background_event_count, dropped_frame_count, session_valid,
            timing_deviation_count, validity_issues
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_TRIAL_SQL = """
        INSERT INTO games.continuous_attention_trials (
            session_id, phase, block_index, trial_index,
            previous_letter, current_letter, response_code, correct,
            latency_ms, scheduled_onset_ms, actual_onset_ms,
            response_timestamp_ms, actual_display_duration_ms,
            actual_isi_duration_ms, input_source, extra_response_count,
            interrupted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;

    private final JdbcTemplate jdbc;

    public ContinuousAttentionMetricsRepositoryAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void replace(UUID sessionId,
                        ContinuousAttentionMetrics metrics,
                        ContinuousAttentionReport report) {
        jdbc.update(DELETE_RUN_SQL, sessionId);
        jdbc.update(INSERT_RUN_SQL,
            sessionId,
            metrics.protocolVersion(),
            metrics.sessionCompleted(),
            report.interrupted(),
            metrics.backgroundEventCount(),
            metrics.droppedFrameCount(),
            report.sessionValid(),
            report.timingDeviationCount(),
            String.join(",", report.validityIssues()));

        List<Object[]> arguments =
            new ArrayList<>(ContinuousAttentionConfig.TOTAL_TRIAL_COUNT);
        for (ContinuousAttentionBlockMetric block : metrics.blocks()) {
            for (ContinuousAttentionTrialMetric trial : block.trials()) {
                arguments.add(new Object[] {
                    sessionId,
                    block.phase().name(),
                    block.blockIndex(),
                    trial.trialIndex(),
                    trial.previousLetter(),
                    trial.currentLetter(),
                    trial.responseCode(),
                    trial.correct(),
                    trial.latencyMs(),
                    trial.scheduledOnsetMs(),
                    trial.actualOnsetMs(),
                    trial.responseTimestampMs(),
                    trial.actualDisplayDurationMs(),
                    trial.actualIsiDurationMs(),
                    trial.inputSource() == null ? null : trial.inputSource().name(),
                    trial.extraResponseCount(),
                    trial.interrupted()
                });
            }
        }
        if (arguments.size() != ContinuousAttentionConfig.TOTAL_TRIAL_COUNT) {
            throw new IllegalStateException(
                "Nombre d'essais à persister inattendu : " + arguments.size());
        }
        jdbc.batchUpdate(INSERT_TRIAL_SQL, arguments);
    }
}
