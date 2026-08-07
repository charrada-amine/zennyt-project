package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.service.ContinuousAttentionScoringService;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;
import com.zennyt.games.support.ContinuousAttentionTestFixtures;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class ContinuousAttentionMetricsRepositoryAdapterTest {

    @Test
    void replacePersistsOneRunAndExactly1364OrderedRawTrials() {
        UUID sessionId =
            UUID.fromString("00000000-0000-4000-8000-000000000001");
        ContinuousAttentionMetrics metrics =
            ContinuousAttentionTestFixtures.perfect(sessionId);
        ContinuousAttentionReport report =
            new ContinuousAttentionScoringService().report(sessionId, metrics);
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        ContinuousAttentionMetricsRepositoryAdapter adapter =
            new ContinuousAttentionMetricsRepositoryAdapter(jdbc);

        adapter.replace(sessionId, metrics, report);

        verify(jdbc).update(
            ContinuousAttentionMetricsRepositoryAdapter.DELETE_RUN_SQL, sessionId);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Object[]>> rows = ArgumentCaptor.forClass(List.class);
        verify(jdbc).batchUpdate(
            eq(ContinuousAttentionMetricsRepositoryAdapter.INSERT_TRIAL_SQL),
            rows.capture());
        assertEquals(ContinuousAttentionConfig.TOTAL_TRIAL_COUNT,
            rows.getValue().size());

        Object[] first = rows.getValue().get(0);
        assertEquals(sessionId, first[0]);
        assertEquals("X_PRACTICE", first[1]);
        assertEquals(1, first[2]);
        assertEquals(1, first[3]);
        assertNull(first[4], "previousLetter reset uniquement au début de famille");

        Object[] last = rows.getValue().get(rows.getValue().size() - 1);
        assertEquals("AX_TEST", last[1]);
        assertEquals(20, last[2]);
        assertEquals(31, last[3]);
    }
}
