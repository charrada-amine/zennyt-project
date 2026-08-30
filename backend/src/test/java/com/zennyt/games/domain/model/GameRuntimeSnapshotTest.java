package com.zennyt.games.domain.model;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class GameRuntimeSnapshotTest {
    @Test
    void defensivelyCopiesPublishedValues() {
        Map<String, Object> source = new HashMap<>();
        Map<String, Object> nested = new HashMap<>();
        nested.put("enabled", true);
        source.put("sceneCount", 2);
        source.put("accessibility", nested);

        GameRuntimeSnapshot snapshot = new GameRuntimeSnapshot(1, null, source, Map.of());
        source.put("sceneCount", 99);
        nested.put("enabled", false);

        assertEquals(2, snapshot.settingInt("sceneCount", 3, 1, 15));
        assertEquals(true,
            ((Map<?, ?>) snapshot.settings().get("accessibility")).get("enabled"));
        assertThrows(UnsupportedOperationException.class,
            () -> snapshot.settings().put("sceneCount", 4));
        assertThrows(UnsupportedOperationException.class,
            () -> ((Map<Object, Object>) snapshot.settings().get("accessibility"))
                .put("enabled", false));
    }

    @Test
    void clampsNumericPresentationControls() {
        GameRuntimeSnapshot snapshot = new GameRuntimeSnapshot(1, null,
            Map.of("sceneCount", 999), Map.of());

        assertEquals(15, snapshot.settingInt("sceneCount", 3, 1, 15));
    }
}
