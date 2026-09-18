package com.zennyt.games.domain;

import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.config.DecisionConfig;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class DecisionActiveFormTest {
    @Test
    void active_bank_retires_ii_without_mutating_archive_or_dt_context() {
        List<DecisionFormCatalog.Content> archive = new ArrayList<>();
        for (DecisionDimension dimension : DecisionDimension.values()) {
            for (int i = 1; i <= DecisionConfig.ITEMS_PER_DIMENSION; i++) {
                archive.add(new DecisionFormCatalog.Content(dimension + "-" + i,
                    dimension, dimension == DecisionDimension.DT
                        ? DecisionItemFormat.TEMPORAL_DECISION : DecisionItemFormat.STANDARD,
                    null, "Contexte II déjà résolu pour DT", "Consigne", false, List.of()));
            }
        }
        DecisionFormCatalog catalog = formCode -> List.copyOf(archive);
        List<DecisionFormCatalog.Content> active = catalog.activeBank(UUID.randomUUID(), "A");
        assertEquals(24, active.size());
        assertEquals(30, catalog.form("A").size());
        assertFalse(active.stream().anyMatch(item -> item.dimension() == DecisionDimension.II));
        assertEquals(archive.stream().filter(item -> item.dimension() != DecisionDimension.II).toList(), active);
        assertEquals(6, active.stream().filter(item -> item.dimension() == DecisionDimension.DT).count());
        assertTrue(active.stream().filter(item -> item.dimension() == DecisionDimension.DT)
            .allMatch(item -> item.vignette().equals("Contexte II déjà résolu pour DT")));
    }
}
