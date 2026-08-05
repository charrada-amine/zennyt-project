package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ObjectLocationConfig;

import java.util.List;
import java.util.Objects;

/** Timings et actions brutes d'un niveau de « Je place ». */
public record ObjectLocationLevelMetric(
    ObjectLocationPhase phase,
    int levelIndex,
    int objectCount,
    int actualEncodingDurationMs,
    int actualRetentionDurationMs,
    int actualRecallDurationMs,
    boolean timedOut,
    boolean completed,
    List<ObjectLocationPlacementAction> actions
) {
    public ObjectLocationLevelMetric {
        Objects.requireNonNull(phase, "phase");
        if (levelIndex < 0 || levelIndex > ObjectLocationConfig.TEST_OBJECT_COUNTS.size()) {
            throw new IllegalArgumentException("levelIndex hors protocole");
        }
        if (objectCount < ObjectLocationConfig.PRACTICE_OBJECT_COUNT
            || objectCount > ObjectLocationConfig.GRID_CELL_COUNT) {
            throw new IllegalArgumentException("objectCount hors limites");
        }
        if (actualEncodingDurationMs < 0 || actualRetentionDurationMs < 0
            || actualRecallDurationMs < 0) {
            throw new IllegalArgumentException("Les durées doivent être positives");
        }
        if (actualEncodingDurationMs
                > ObjectLocationConfig.encodingDurationMs(objectCount)
                    + ObjectLocationConfig.RECALL_TECHNICAL_TOLERANCE_MS
            || actualRetentionDurationMs
                > ObjectLocationConfig.RETENTION_MS
                    + ObjectLocationConfig.RECALL_TECHNICAL_TOLERANCE_MS
            || actualRecallDurationMs
                > ObjectLocationConfig.recallLimitMs(objectCount)
                    + ObjectLocationConfig.RECALL_TECHNICAL_TOLERANCE_MS) {
            throw new IllegalArgumentException("Durée hors fenêtre technique maximale");
        }
        if (timedOut && !completed) {
            throw new IllegalArgumentException("Un timeout clôt le niveau");
        }
        actions = List.copyOf(Objects.requireNonNull(actions, "actions"));
        if (actions.size() > ObjectLocationConfig.MAX_ACTIONS_PER_LEVEL) {
            throw new IllegalArgumentException("Trop d'actions sur le niveau");
        }
        long previousTimestamp = -1;
        for (int i = 0; i < actions.size(); i++) {
            ObjectLocationPlacementAction action = actions.get(i);
            if (action.actionIndex() != i + 1) {
                throw new IllegalArgumentException("Les actions doivent être contiguës et 1-based");
            }
            if (action.timestampMs() < previousTimestamp
                || action.timestampMs() > actualRecallDurationMs) {
                throw new IllegalArgumentException("Chronologie d'actions invalide");
            }
            previousTimestamp = action.timestampMs();
        }
    }
}
