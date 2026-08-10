package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ObjectLocationConfig;

import java.util.List;
import java.util.Objects;

/** Trace brute complète de « Je place ». */
public record ObjectLocationMetrics(
    String protocolVersion,
    ObjectLocationCompletionReason completionReason,
    List<ObjectLocationLevelMetric> levels,
    boolean sessionCompleted,
    boolean interrupted,
    int backgroundEventCount,
    int focusLossCount,
    int orientationChangeCount,
    int droppedFrameCount
) implements GameMetrics {
    public ObjectLocationMetrics {
        if (!ObjectLocationConfig.PROTOCOL_VERSION.equals(protocolVersion)) {
            throw new IllegalArgumentException(
                "protocolVersion attendu : " + ObjectLocationConfig.PROTOCOL_VERSION);
        }
        Objects.requireNonNull(completionReason, "completionReason");
        levels = List.copyOf(Objects.requireNonNull(levels, "levels"));
        if (levels.isEmpty() || levels.size() > 1 + ObjectLocationConfig.TEST_OBJECT_COUNTS.size()) {
            throw new IllegalArgumentException("Nombre de niveaux hors protocole");
        }
        if (backgroundEventCount < 0 || focusLossCount < 0
            || orientationChangeCount < 0 || droppedFrameCount < 0) {
            throw new IllegalArgumentException("Les compteurs techniques doivent être positifs");
        }
        boolean technicalInterruption =
            completionReason == ObjectLocationCompletionReason.TECHNICAL_INTERRUPTION;
        if (sessionCompleted == technicalInterruption) {
            throw new IllegalArgumentException("completionReason incompatible avec sessionCompleted");
        }
        validateStructure(levels);
    }

    private static void validateStructure(List<ObjectLocationLevelMetric> levels) {
        for (int i = 0; i < levels.size(); i++) {
            ObjectLocationLevelMetric level = levels.get(i);
            ObjectLocationPhase expectedPhase = i == 0
                ? ObjectLocationPhase.PRACTICE : ObjectLocationPhase.TEST;
            int expectedIndex = i;
            int expectedCount = ObjectLocationConfig.expectedObjectCount(
                expectedPhase, expectedIndex);
            if (level.phase() != expectedPhase
                || level.levelIndex() != expectedIndex
                || level.objectCount() != expectedCount) {
                throw new IllegalArgumentException(
                    "Progression de niveaux invalide à l'index " + i);
            }
            if (!level.completed() && i != levels.size() - 1) {
                throw new IllegalArgumentException(
                    "Seul le dernier niveau peut être incomplet");
            }
        }
    }
}
