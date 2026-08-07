package com.zennyt.games.support;

import com.zennyt.games.domain.config.ObjectLocationConfig;
import com.zennyt.games.domain.service.ObjectLocationLayoutGenerator;
import com.zennyt.games.domain.vo.ObjectLocationActionType;
import com.zennyt.games.domain.vo.ObjectLocationCompletionReason;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPlacementAction;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Fixtures déterministes partagées par domaine, application et persistance. */
public final class ObjectLocationTestFixtures {

    public static final UUID SESSION_ID =
        UUID.fromString("00000000-0000-4000-8000-000000000004");

    private ObjectLocationTestFixtures() {
    }

    public static ObjectLocationMetrics perfect(UUID sessionId) {
        List<ObjectLocationLayoutGenerator.GeneratedLevel> layouts =
            new ObjectLocationLayoutGenerator().generate(sessionId);
        List<ObjectLocationLevelMetric> levels = layouts.stream()
            .map(ObjectLocationTestFixtures::perfectLevel).toList();
        return new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.MAX_LEVELS,
            levels, true, false, 0, 0, 0, 0);
    }

    /** Niveau 1 réussi puis niveaux 2 et 3 échoués par timeout. */
    public static ObjectLocationMetrics validStopRule(UUID sessionId) {
        List<ObjectLocationLayoutGenerator.GeneratedLevel> layouts =
            new ObjectLocationLayoutGenerator().generate(sessionId);
        List<ObjectLocationLevelMetric> levels = new ArrayList<>();
        levels.add(perfectLevel(layouts.get(0)));
        levels.add(perfectLevel(layouts.get(1)));
        levels.add(timeoutLevel(layouts.get(2)));
        levels.add(timeoutLevel(layouts.get(3)));
        return new ObjectLocationMetrics(
            ObjectLocationConfig.PROTOCOL_VERSION,
            ObjectLocationCompletionReason.STOP_RULE,
            levels, true, false, 0, 0, 0, 0);
    }

    public static ObjectLocationLevelMetric perfectLevel(
            ObjectLocationLayoutGenerator.GeneratedLevel layout) {
        List<ObjectLocationPlacementAction> actions = new ArrayList<>();
        for (int i = 0; i < layout.objects().size(); i++) {
            var object = layout.objects().get(i);
            actions.add(new ObjectLocationPlacementAction(
                i + 1, ObjectLocationActionType.PLACE, object.objectId(),
                object.originCellIndex(), (i + 1L) * 500L));
        }
        int recallDuration = layout.objectCount() * 600;
        return new ObjectLocationLevelMetric(
            layout.phase(), layout.levelIndex(), layout.objectCount(),
            ObjectLocationConfig.encodingDurationMs(layout.objectCount()),
            ObjectLocationConfig.RETENTION_MS,
            recallDuration, false, true, actions);
    }

    public static ObjectLocationLevelMetric timeoutLevel(
            ObjectLocationLayoutGenerator.GeneratedLevel layout) {
        return new ObjectLocationLevelMetric(
            layout.phase(), layout.levelIndex(), layout.objectCount(),
            ObjectLocationConfig.encodingDurationMs(layout.objectCount()),
            ObjectLocationConfig.RETENTION_MS,
            ObjectLocationConfig.recallLimitMs(layout.objectCount()),
            true, true, List.of());
    }
}
