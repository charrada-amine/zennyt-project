package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.vo.EmotionalRadarScene;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Random;

/** Applies only non-scoring runtime presentation controls to an immutable scene catalog. */
final class EmotionalRadarRuntimeSelection {
    private EmotionalRadarRuntimeSelection() {}

    static List<EmotionalRadarScene> select(GameSession session,
                                            List<EmotionalRadarScene> catalogScenes) {
        if (catalogScenes.isEmpty()) return List.of();
        List<EmotionalRadarScene> selected = new ArrayList<>(catalogScenes);
        String orderMode = session.runtimeSnapshot()
            .settingString("orderMode", "SEQUENTIAL").toUpperCase(Locale.ROOT);
        if ("SHUFFLED".equals(orderMode)) {
            UUIDSeed seed = new UUIDSeed(session.id().getMostSignificantBits(),
                session.id().getLeastSignificantBits());
            Collections.shuffle(selected, new Random(seed.value()));
        }
        int sceneCount = session.runtimeSnapshot()
            .settingInt("sceneCount", selected.size(), 1, selected.size());
        return List.copyOf(selected.subList(0, sceneCount));
    }

    private record UUIDSeed(long most, long least) {
        long value() { return most ^ least; }
    }
}
