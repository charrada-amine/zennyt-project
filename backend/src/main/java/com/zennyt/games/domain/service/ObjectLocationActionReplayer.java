package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.ObjectLocationActionType;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationPlacementAction;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Rejoue les actions brutes selon les mêmes règles que l'interface. */
public final class ObjectLocationActionReplayer {

    public record Replay(
        Map<String, Integer> finalCellsByObject,
        int repositionCount,
        Double averageFirstPlacementIntervalMs,
        int firstPlacementIntervalCount
    ) {
        public Replay {
            finalCellsByObject = Map.copyOf(finalCellsByObject);
        }
    }

    public Replay replay(ObjectLocationLayoutGenerator.GeneratedLevel layout,
                         ObjectLocationLevelMetric metrics) {
        Map<String, Integer> objectToCell = new HashMap<>();
        Map<Integer, String> cellToObject = new HashMap<>();
        Set<String> everPlaced = new HashSet<>();
        List<Long> firstPlacementTimestamps = new ArrayList<>();
        int repositionCount = 0;

        for (ObjectLocationPlacementAction action : metrics.actions()) {
            Integer previousCell = objectToCell.remove(action.objectId());
            if (previousCell != null) cellToObject.remove(previousCell);

            if (action.actionType() == ObjectLocationActionType.RETURN_TO_RESERVE) {
                continue;
            }
            if (!everPlaced.add(action.objectId())) {
                repositionCount++;
            } else {
                firstPlacementTimestamps.add(action.timestampMs());
            }
            String displaced = cellToObject.remove(action.targetCellIndex());
            if (displaced != null) objectToCell.remove(displaced);
            cellToObject.put(action.targetCellIndex(), action.objectId());
            objectToCell.put(action.objectId(), action.targetCellIndex());
        }

        Double averageInterval = null;
        if (firstPlacementTimestamps.size() >= 2) {
            long total = 0;
            for (int i = 1; i < firstPlacementTimestamps.size(); i++) {
                total += firstPlacementTimestamps.get(i)
                    - firstPlacementTimestamps.get(i - 1);
            }
            averageInterval = total * 1.0 / (firstPlacementTimestamps.size() - 1);
        }
        return new Replay(objectToCell, repositionCount, averageInterval,
            Math.max(0, firstPlacementTimestamps.size() - 1));
    }
}
