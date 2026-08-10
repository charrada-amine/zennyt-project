package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.ObjectLocationPhase;
import com.zennyt.games.domain.vo.ObjectLocationReserveZone;

import java.util.List;

/**
 * Source de vérité du protocole « Je place ».
 *
 * <p>La grille, la progression et les timings sont isolés ici pour pouvoir être
 * remplacés après validation psychométrique sans modifier le moteur de layout,
 * de rejeu des actions ou de persistance.
 */
public final class ObjectLocationConfig {

    public static final String PROTOCOL_VERSION = "OBJECT_LOCATION_FINE_V1";
    public static final int GRID_SIDE = 4;
    public static final int GRID_CELL_COUNT = GRID_SIDE * GRID_SIDE;
    public static final int PRACTICE_OBJECT_COUNT = 2;

    // PROVISOIRE — non validé par le psychologue.
    public static final List<Integer> TEST_OBJECT_COUNTS =
        List.of(3, 4, 5, 6, 7, 8);
    // PROVISOIRE — non validé par le psychologue.
    public static final int ENCODING_MS_PER_OBJECT = 1_500;
    // PROVISOIRE — non validé par le psychologue.
    public static final int RETENTION_MS = 2_000;
    // PROVISOIRE — non validé par le psychologue.
    public static final int RECALL_MS_PER_OBJECT = 4_000;
    // PROVISOIRE — borne anti-tap accidentel, non validée par le psychologue.
    public static final int MIN_RECALL_MS_PER_OBJECT = 150;
    // PROVISOIRE — à valider sur appareils réels.
    public static final int TIMING_TOLERANCE_MS = 100;
    public static final int RECALL_TECHNICAL_TOLERANCE_MS = 250;
    // PROVISOIRE — non validé par le psychologue.
    public static final int PASS_PERCENT = 60;
    // PROVISOIRE — non validé par le psychologue.
    public static final int MIN_VALID_TEST_LEVELS = 3;
    // PROVISOIRE — non validé par le psychologue.
    public static final int CONSECUTIVE_FAILURES_TO_STOP = 2;
    public static final int MAX_LAYOUT_DRAWS = 256;
    public static final int MAX_ACTIONS_PER_LEVEL = 256;
    public static final int ZERO_SEED_FALLBACK = 0x6D2B79F5;
    public static final double MAX_CELL_DISTANCE = Math.sqrt(18.0);

    /** Catalogue V1 : identifiants stables, modernes et sans contenu clinique. */
    public static final List<String> OBJECT_CATALOG_V1 = List.of(
        "SMARTPHONE",
        "WIRELESS_EARBUDS",
        "SMARTWATCH",
        "REUSABLE_BOTTLE",
        "INSTANT_CAMERA",
        "SNEAKER",
        "SUCCULENT",
        "CERAMIC_MUG",
        "BACKPACK",
        "GAME_CONTROLLER",
        "BICYCLE_HELMET",
        "DESK_LAMP",
        "NOTEBOOK",
        "SUNGLASSES",
        "KEYCARD",
        "COMPACT_DRONE",
        "PORTABLE_SPEAKER",
        "POWER_BANK",
        "STYLUS_TABLET",
        "TRAVEL_POUCH");

    private ObjectLocationConfig() {
    }

    public static int expectedObjectCount(ObjectLocationPhase phase, int levelIndex) {
        if (phase == ObjectLocationPhase.PRACTICE && levelIndex == 0) {
            return PRACTICE_OBJECT_COUNT;
        }
        if (phase == ObjectLocationPhase.TEST
            && levelIndex >= 1 && levelIndex <= TEST_OBJECT_COUNTS.size()) {
            return TEST_OBJECT_COUNTS.get(levelIndex - 1);
        }
        throw new IllegalArgumentException("Niveau hors protocole : " + phase + " #" + levelIndex);
    }

    public static int encodingDurationMs(int objectCount) {
        return Math.multiplyExact(ENCODING_MS_PER_OBJECT, objectCount);
    }

    public static int recallLimitMs(int objectCount) {
        return Math.multiplyExact(RECALL_MS_PER_OBJECT, objectCount);
    }

    public static int passThreshold(int objectCount) {
        return (objectCount * PASS_PERCENT + 99) / 100;
    }

    /** Position de réserve prescrite par la fiche, versionnée avec le protocole. */
    public static ObjectLocationReserveZone reserveZone(
            ObjectLocationPhase phase, int levelIndex) {
        if (phase == ObjectLocationPhase.PRACTICE && levelIndex == 0) {
            return ObjectLocationReserveZone.BELOW;
        }
        if (phase != ObjectLocationPhase.TEST) {
            throw new IllegalArgumentException("Niveau hors protocole");
        }
        return switch (levelIndex) {
            case 1, 5 -> ObjectLocationReserveZone.BELOW;
            case 2, 6 -> ObjectLocationReserveZone.LEFT;
            case 3 -> ObjectLocationReserveZone.RIGHT;
            case 4 -> ObjectLocationReserveZone.BOTH;
            default -> throw new IllegalArgumentException("Niveau hors protocole");
        };
    }
}
