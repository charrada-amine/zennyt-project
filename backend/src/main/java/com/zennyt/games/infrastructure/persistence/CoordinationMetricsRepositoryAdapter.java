package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationPointerSample;
import com.zennyt.games.domain.vo.CoordinationReport;
import com.zennyt.games.domain.vo.CoordinationSegmentMetric;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Persistance JDBC des positions brutes de « Je coordonne ». Le remplacement
 * est atomique car il est appelé dans la transaction du use case de soumission.
 */
@Component
public class CoordinationMetricsRepositoryAdapter
        implements CoordinationMetricsRepository {

    static final String DELETE_RUN_SQL =
        "DELETE FROM games.coordination_tracking_runs WHERE session_id = ?";
    static final String INSERT_RUN_SQL = """
        INSERT INTO games.coordination_tracking_runs (
            session_id, protocol_version, input_source, session_completed,
            interrupted, background_event_count, dropped_frame_count,
            session_valid, provisional_accuracy_score,
            overall_accuracy_percent, fast_accuracy_percent,
            slow_accuracy_percent, long_accuracy_percent,
            short_accuracy_percent, average_center_distance,
            test_execution_time_ms, accuracy_valid, execution_time_valid,
            task_valid, technical_valid, sample_count, absent_sample_count,
            timing_deviation_count, sampling_gap_count, validity_issues
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                  ?, ?, ?, ?, ?)
        """;
    static final String INSERT_SEGMENT_SQL = """
        INSERT INTO games.coordination_tracking_segments (
            session_id, segment_index, phase, speed, nominal_duration_ms,
            actual_start_ms, actual_end_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """;
    static final String INSERT_SAMPLE_SQL = """
        INSERT INTO games.coordination_tracking_samples (
            session_id, segment_index, sample_index, timestamp_ms,
            pointer_present, pointer_x, pointer_y
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """;

    private final JdbcTemplate jdbc;

    public CoordinationMetricsRepositoryAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void replace(UUID sessionId,
                        CoordinationMetrics metrics,
                        CoordinationReport report) {
        jdbc.update(DELETE_RUN_SQL, sessionId);
        jdbc.update(INSERT_RUN_SQL,
            sessionId,
            metrics.protocolVersion(),
            metrics.inputSource().name(),
            metrics.sessionCompleted(),
            report.interrupted(),
            metrics.backgroundEventCount(),
            metrics.droppedFrameCount(),
            report.sessionValid(),
            report.provisionalAccuracyScore(),
            report.overallAccuracyPercent(),
            report.fastAccuracyPercent(),
            report.slowAccuracyPercent(),
            report.longSegmentAccuracyPercent(),
            report.shortSegmentAccuracyPercent(),
            report.averageCenterDistance(),
            report.testExecutionTimeMs(),
            report.accuracyValid(),
            report.executionTimeValid(),
            report.taskValid(),
            report.technicalValid(),
            report.sampleCount(),
            report.absentSampleCount(),
            report.timingDeviationCount(),
            report.samplingGapCount(),
            String.join(",", report.validityIssues()));

        List<Object[]> segments = new ArrayList<>(metrics.segments().size());
        List<Object[]> samples = new ArrayList<>();
        for (CoordinationSegmentMetric segment : metrics.segments()) {
            segments.add(new Object[] {
                sessionId,
                segment.segmentIndex(),
                segment.phase().name(),
                segment.speed().name(),
                segment.nominalDurationMs(),
                segment.actualStartMs(),
                segment.actualEndMs()
            });
            for (CoordinationPointerSample sample : segment.samples()) {
                samples.add(new Object[] {
                    sessionId,
                    segment.segmentIndex(),
                    sample.sampleIndex(),
                    sample.timestampMs(),
                    sample.pointerPresent(),
                    sample.pointerX(),
                    sample.pointerY()
                });
            }
        }
        jdbc.batchUpdate(INSERT_SEGMENT_SQL, segments);
        jdbc.batchUpdate(INSERT_SAMPLE_SQL, samples);
    }
}
