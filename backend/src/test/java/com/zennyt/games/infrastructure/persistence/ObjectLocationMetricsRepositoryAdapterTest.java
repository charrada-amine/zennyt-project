package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.service.ObjectLocationScoringService;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationReport;
import com.zennyt.games.support.ObjectLocationTestFixtures;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class ObjectLocationMetricsRepositoryAdapterTest {

    @Test
    void replacePersistsRunSevenLevelsAndEveryRawAction() {
        ObjectLocationMetrics metrics = ObjectLocationTestFixtures.perfect(
            ObjectLocationTestFixtures.SESSION_ID);
        ObjectLocationReport report = new ObjectLocationScoringService().report(
            ObjectLocationTestFixtures.SESSION_ID, metrics);
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        ObjectLocationMetricsRepositoryAdapter adapter =
            new ObjectLocationMetricsRepositoryAdapter(jdbc);

        adapter.replace(ObjectLocationTestFixtures.SESSION_ID, metrics, report);

        verify(jdbc).update(
            ObjectLocationMetricsRepositoryAdapter.DELETE_RUN_SQL,
            ObjectLocationTestFixtures.SESSION_ID);
        ArgumentCaptor<Object[]> runArguments = ArgumentCaptor.forClass(Object[].class);
        verify(jdbc).update(
            eq(ObjectLocationMetricsRepositoryAdapter.INSERT_RUN_SQL),
            runArguments.capture());
        assertEquals(ObjectLocationTestFixtures.SESSION_ID,
            runArguments.getValue()[0]);
        assertEquals("OBJECT_LOCATION_FINE_V1", runArguments.getValue()[1]);
        assertEquals("MAX_LEVELS", runArguments.getValue()[2]);
        assertTrue((Boolean) runArguments.getValue()[9]);
        assertEquals(100, runArguments.getValue()[14]);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Object[]>> levelRows = ArgumentCaptor.forClass(List.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Object[]>> actionRows = ArgumentCaptor.forClass(List.class);
        verify(jdbc).batchUpdate(
            eq(ObjectLocationMetricsRepositoryAdapter.INSERT_LEVEL_SQL),
            levelRows.capture());
        verify(jdbc).batchUpdate(
            eq(ObjectLocationMetricsRepositoryAdapter.INSERT_ACTION_SQL),
            actionRows.capture());

        assertEquals(7, levelRows.getValue().size());
        assertEquals(35, actionRows.getValue().size());
        Object[] practice = levelRows.getValue().get(0);
        assertEquals(0, practice[1]);
        assertEquals("PRACTICE", practice[2]);
        assertEquals(2, practice[3]);
        Object[] last = levelRows.getValue().get(6);
        assertEquals(6, last[1]);
        assertEquals("TEST", last[2]);
        assertEquals(8, last[3]);
        Object[] firstAction = actionRows.getValue().get(0);
        assertEquals("PLACE", firstAction[3]);
        assertEquals("SMARTPHONE", firstAction[4]);
        assertEquals(13, firstAction[5]);
    }
}
