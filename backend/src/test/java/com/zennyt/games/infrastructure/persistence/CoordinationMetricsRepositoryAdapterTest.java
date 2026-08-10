package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.config.CoordinationConfig;
import com.zennyt.games.domain.service.CoordinationScoringService;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationReport;
import com.zennyt.games.support.CoordinationTestFixtures;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class CoordinationMetricsRepositoryAdapterTest {

    @Test
    void replacePersistsRunFourteenSegmentsAndEveryRawPointerSample() {
        UUID sessionId =
            UUID.fromString("00000000-0000-4000-8000-000000000002");
        CoordinationMetrics metrics = CoordinationTestFixtures.perfect();
        CoordinationReport report =
            new CoordinationScoringService().report(metrics);
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        CoordinationMetricsRepositoryAdapter adapter =
            new CoordinationMetricsRepositoryAdapter(jdbc);

        adapter.replace(sessionId, metrics, report);

        verify(jdbc).update(
            CoordinationMetricsRepositoryAdapter.DELETE_RUN_SQL, sessionId);
        ArgumentCaptor<Object[]> runArguments =
            ArgumentCaptor.forClass(Object[].class);
        verify(jdbc).update(
            eq(CoordinationMetricsRepositoryAdapter.INSERT_RUN_SQL),
            runArguments.capture());
        assertEquals(sessionId, runArguments.getValue()[0]);
        assertEquals("FIXED_SQUARE_CW_V1", runArguments.getValue()[1]);
        assertEquals("TOUCH", runArguments.getValue()[2]);
        assertTrue((Boolean) runArguments.getValue()[7]);
        assertTrue((Boolean) runArguments.getValue()[18]);
        assertTrue((Boolean) runArguments.getValue()[19]);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Object[]>> segmentRows =
            ArgumentCaptor.forClass(List.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Object[]>> sampleRows =
            ArgumentCaptor.forClass(List.class);
        verify(jdbc).batchUpdate(
            eq(CoordinationMetricsRepositoryAdapter.INSERT_SEGMENT_SQL),
            segmentRows.capture());
        verify(jdbc).batchUpdate(
            eq(CoordinationMetricsRepositoryAdapter.INSERT_SAMPLE_SQL),
            sampleRows.capture());

        assertEquals(CoordinationConfig.TOTAL_SEGMENT_COUNT,
            segmentRows.getValue().size());
        int expectedSamples = metrics.segments().stream()
            .mapToInt(segment -> segment.samples().size()).sum();
        assertEquals(expectedSamples, sampleRows.getValue().size());

        Object[] firstSegment = segmentRows.getValue().get(0);
        assertEquals(sessionId, firstSegment[0]);
        assertEquals(1, firstSegment[1]);
        assertEquals("PRACTICE", firstSegment[2]);
        assertEquals("SLOW", firstSegment[3]);

        Object[] lastSegment = segmentRows.getValue().get(13);
        assertEquals(14, lastSegment[1]);
        assertEquals("TEST", lastSegment[2]);
        assertEquals("FAST", lastSegment[3]);

        Object[] firstSample = sampleRows.getValue().get(0);
        assertEquals(sessionId, firstSample[0]);
        assertEquals(1, firstSample[1]);
        assertEquals(1, firstSample[2]);
        assertEquals(0L, firstSample[3]);
        assertTrue((Boolean) firstSample[4]);
    }
}
