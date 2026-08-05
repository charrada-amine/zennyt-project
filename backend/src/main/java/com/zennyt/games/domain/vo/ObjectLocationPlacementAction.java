package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ObjectLocationConfig;

import java.util.Objects;

/** Action brute ; aucune correction ni position attendue n'est fournie par le client. */
public record ObjectLocationPlacementAction(
    int actionIndex,
    ObjectLocationActionType actionType,
    String objectId,
    Integer targetCellIndex,
    long timestampMs
) {
    public ObjectLocationPlacementAction {
        if (actionIndex < 1 || actionIndex > ObjectLocationConfig.MAX_ACTIONS_PER_LEVEL) {
            throw new IllegalArgumentException("actionIndex hors limites");
        }
        Objects.requireNonNull(actionType, "actionType");
        objectId = Objects.requireNonNull(objectId, "objectId").trim();
        if (objectId.isEmpty() || objectId.length() > 48) {
            throw new IllegalArgumentException("objectId invalide");
        }
        if (timestampMs < 0) {
            throw new IllegalArgumentException("timestampMs doit être positif");
        }
        if (actionType == ObjectLocationActionType.PLACE) {
            if (targetCellIndex == null || targetCellIndex < 0
                || targetCellIndex >= ObjectLocationConfig.GRID_CELL_COUNT) {
                throw new IllegalArgumentException("PLACE exige une cellule de la grille");
            }
        } else if (targetCellIndex != null) {
            throw new IllegalArgumentException("RETURN_TO_RESERVE exige targetCellIndex=null");
        }
    }
}
