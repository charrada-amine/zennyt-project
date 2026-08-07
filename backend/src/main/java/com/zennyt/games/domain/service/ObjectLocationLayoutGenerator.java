package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.ObjectLocationConfig;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPhase;
import com.zennyt.games.domain.vo.ObjectLocationReserveSide;
import com.zennyt.games.domain.vo.ObjectLocationReserveZone;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Génère les objets, origines et réserves de « Je place » depuis l'UUID.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : FNV-1a 32 bits, xorshift32, modulo non signé,
 * Fisher-Yates et ordre exact des tirages sont reproduits côté mobile. Le
 * client ne peut donc ni choisir les objets ni déclarer les bonnes cellules.
 */
public final class ObjectLocationLayoutGenerator {

    private static final List<Integer> FALLBACK_PATTERN =
        List.of(0, 5, 10, 3, 12, 7, 9, 14, 1, 6, 11, 4, 13, 2, 8, 15);

    public record GeneratedObject(
        String objectId,
        int originCellIndex,
        ObjectLocationReserveSide reserveSide,
        int reserveOrder
    ) {
    }

    public record GeneratedLevel(
        ObjectLocationPhase phase,
        int levelIndex,
        int objectCount,
        ObjectLocationReserveZone reserveZone,
        List<GeneratedObject> objects
    ) {
        public GeneratedLevel {
            objects = List.copyOf(objects);
        }

        public Map<String, Integer> originsByObject() {
            Map<String, Integer> result = new LinkedHashMap<>();
            for (GeneratedObject object : objects) {
                result.put(object.objectId(), object.originCellIndex());
            }
            return Map.copyOf(result);
        }
    }

    public List<GeneratedLevel> generate(UUID sessionId) {
        String material = sessionId.toString().toLowerCase(Locale.ROOT)
            + "|" + ObjectLocationConfig.PROTOCOL_VERSION;
        XorShift32 random = new XorShift32(fnv1a32(material));
        int[] useCounts = new int[ObjectLocationConfig.OBJECT_CATALOG_V1.size()];
        Map<Integer, Set<Integer>> priorCellsByObject = new HashMap<>();
        List<GeneratedLevel> result = new ArrayList<>(
            1 + ObjectLocationConfig.TEST_OBJECT_COUNTS.size());

        result.add(generateLevel(ObjectLocationPhase.PRACTICE, 0,
            ObjectLocationConfig.PRACTICE_OBJECT_COUNT, random,
            useCounts, priorCellsByObject));
        for (int levelIndex = 1;
             levelIndex <= ObjectLocationConfig.TEST_OBJECT_COUNTS.size();
             levelIndex++) {
            result.add(generateLevel(ObjectLocationPhase.TEST, levelIndex,
                ObjectLocationConfig.expectedObjectCount(
                    ObjectLocationPhase.TEST, levelIndex),
                random, useCounts, priorCellsByObject));
        }
        return List.copyOf(result);
    }

    /** Rejette les IDs ou l'état final impossibles avant toute persistance. */
    public void validate(UUID sessionId, ObjectLocationMetrics metrics) {
        List<GeneratedLevel> expected = generate(sessionId);
        ObjectLocationActionReplayer replayer = new ObjectLocationActionReplayer();
        for (int i = 0; i < metrics.levels().size(); i++) {
            GeneratedLevel layout = expected.get(i);
            ObjectLocationLevelMetric actual = metrics.levels().get(i);
            Set<String> expectedIds = layout.originsByObject().keySet();
            for (var action : actual.actions()) {
                if (!expectedIds.contains(action.objectId())) {
                    throw new IllegalArgumentException(
                        "Objet différent du layout déterministe au niveau "
                            + actual.levelIndex() + " : " + action.objectId());
                }
            }
            ObjectLocationActionReplayer.Replay replay =
                replayer.replay(layout, actual);
            if (actual.completed() && !actual.timedOut()
                && replay.finalCellsByObject().size() != actual.objectCount()) {
                throw new IllegalArgumentException(
                    "Un niveau validé sans timeout exige tous les objets placés");
            }
        }
    }

    private static GeneratedLevel generateLevel(
            ObjectLocationPhase phase,
            int levelIndex,
            int objectCount,
            XorShift32 random,
            int[] useCounts,
            Map<Integer, Set<Integer>> priorCellsByObject) {
        List<Integer> objectIndexes = selectBalancedObjects(
            objectCount, random, useCounts);
        Map<Integer, Integer> cells = selectCells(
            objectIndexes, random, priorCellsByObject);
        ObjectLocationReserveZone zone =
            ObjectLocationConfig.reserveZone(phase, levelIndex);
        Map<Integer, ReservePlacement> reserves = reservePlacements(
            objectIndexes, zone, random);

        List<GeneratedObject> objects = new ArrayList<>(objectCount);
        for (int objectIndex : objectIndexes) {
            int cell = cells.get(objectIndex);
            priorCellsByObject.computeIfAbsent(objectIndex, ignored -> new HashSet<>())
                .add(cell);
            ReservePlacement reserve = reserves.get(objectIndex);
            objects.add(new GeneratedObject(
                ObjectLocationConfig.OBJECT_CATALOG_V1.get(objectIndex),
                cell, reserve.side(), reserve.order()));
        }
        return new GeneratedLevel(phase, levelIndex, objectCount, zone, objects);
    }

    private static List<Integer> selectBalancedObjects(
            int objectCount, XorShift32 random, int[] useCounts) {
        List<Integer> selected = new ArrayList<>(objectCount);
        Set<Integer> selectedSet = new HashSet<>();
        while (selected.size() < objectCount) {
            int minimum = Integer.MAX_VALUE;
            for (int i = 0; i < useCounts.length; i++) {
                if (!selectedSet.contains(i)) minimum = Math.min(minimum, useCounts[i]);
            }
            List<Integer> candidates = new ArrayList<>();
            for (int i = 0; i < useCounts.length; i++) {
                if (!selectedSet.contains(i) && useCounts[i] == minimum) {
                    candidates.add(i);
                }
            }
            fisherYates(candidates, random);
            int chosen = candidates.get(0);
            selected.add(chosen);
            selectedSet.add(chosen);
            useCounts[chosen]++;
        }
        return selected;
    }

    private static Map<Integer, Integer> selectCells(
            List<Integer> objectIndexes,
            XorShift32 random,
            Map<Integer, Set<Integer>> priorCellsByObject) {
        for (int draw = 0; draw < ObjectLocationConfig.MAX_LAYOUT_DRAWS; draw++) {
            List<Integer> cells = allCells();
            fisherYates(cells, random);
            cells = new ArrayList<>(cells.subList(0, objectIndexes.size()));
            if (!containsCompleteLine(cells)) {
                Map<Integer, Integer> assignment = matchCells(
                    objectIndexes, cells, priorCellsByObject);
                if (assignment != null) return assignment;
            }
        }

        // Fallback borné et déterministe : translations toroïdales d'un motif
        // sans ligne régulière, puis appariement évitant la cellule précédente.
        for (int rowOffset = 0; rowOffset < ObjectLocationConfig.GRID_SIDE; rowOffset++) {
            for (int columnOffset = 0;
                 columnOffset < ObjectLocationConfig.GRID_SIDE;
                 columnOffset++) {
                List<Integer> translated = new ArrayList<>(objectIndexes.size());
                for (int i = 0; i < objectIndexes.size(); i++) {
                    int cell = FALLBACK_PATTERN.get(i);
                    int row = (cell / ObjectLocationConfig.GRID_SIDE + rowOffset)
                        % ObjectLocationConfig.GRID_SIDE;
                    int column = (cell % ObjectLocationConfig.GRID_SIDE + columnOffset)
                        % ObjectLocationConfig.GRID_SIDE;
                    translated.add(row * ObjectLocationConfig.GRID_SIDE + column);
                }
                if (!containsCompleteLine(translated)) {
                    Map<Integer, Integer> assignment = matchCells(
                        objectIndexes, translated, priorCellsByObject);
                    if (assignment != null) return assignment;
                }
            }
        }
        throw new IllegalStateException("Impossible de générer un layout valide");
    }

    private static Map<Integer, Integer> matchCells(
            List<Integer> objects,
            List<Integer> cells,
            Map<Integer, Set<Integer>> priorCellsByObject) {
        Map<Integer, Integer> assignment = new LinkedHashMap<>();
        return matchCell(0, objects, cells, priorCellsByObject,
            new HashSet<>(), assignment) ? assignment : null;
    }

    private static boolean matchCell(
            int position,
            List<Integer> objects,
            List<Integer> cells,
            Map<Integer, Set<Integer>> priorCellsByObject,
            Set<Integer> used,
            Map<Integer, Integer> assignment) {
        if (position == objects.size()) return true;
        int object = objects.get(position);
        Set<Integer> priorCells = priorCellsByObject.getOrDefault(object, Set.of());
        for (int cell : cells) {
            if (used.contains(cell) || priorCells.contains(cell)) continue;
            used.add(cell);
            assignment.put(object, cell);
            if (matchCell(position + 1, objects, cells,
                priorCellsByObject, used, assignment)) return true;
            assignment.remove(object);
            used.remove(cell);
        }
        return false;
    }

    private static Map<Integer, ReservePlacement> reservePlacements(
            List<Integer> objectIndexes,
            ObjectLocationReserveZone zone,
            XorShift32 random) {
        List<Integer> order = new ArrayList<>(objectIndexes);
        fisherYates(order, random);
        Map<Integer, ReservePlacement> result = new HashMap<>();
        int left = 0;
        int right = 0;
        for (int rank = 0; rank < order.size(); rank++) {
            ObjectLocationReserveSide side;
            int sideOrder;
            if (zone == ObjectLocationReserveZone.BOTH) {
                if (rank % 2 == 0) {
                    side = ObjectLocationReserveSide.LEFT;
                    sideOrder = left++;
                } else {
                    side = ObjectLocationReserveSide.RIGHT;
                    sideOrder = right++;
                }
            } else {
                side = ObjectLocationReserveSide.valueOf(zone.name());
                sideOrder = rank;
            }
            result.put(order.get(rank), new ReservePlacement(side, sideOrder));
        }
        return result;
    }

    private static boolean containsCompleteLine(List<Integer> cells) {
        Set<Integer> occupied = new HashSet<>(cells);
        for (int row = 0; row < ObjectLocationConfig.GRID_SIDE; row++) {
            boolean complete = true;
            for (int column = 0; column < ObjectLocationConfig.GRID_SIDE; column++) {
                complete &= occupied.contains(row * ObjectLocationConfig.GRID_SIDE + column);
            }
            if (complete) return true;
        }
        for (int column = 0; column < ObjectLocationConfig.GRID_SIDE; column++) {
            boolean complete = true;
            for (int row = 0; row < ObjectLocationConfig.GRID_SIDE; row++) {
                complete &= occupied.contains(row * ObjectLocationConfig.GRID_SIDE + column);
            }
            if (complete) return true;
        }
        boolean mainDiagonal = true;
        boolean antiDiagonal = true;
        for (int i = 0; i < ObjectLocationConfig.GRID_SIDE; i++) {
            mainDiagonal &= occupied.contains(i * ObjectLocationConfig.GRID_SIDE + i);
            antiDiagonal &= occupied.contains(
                i * ObjectLocationConfig.GRID_SIDE
                    + ObjectLocationConfig.GRID_SIDE - 1 - i);
        }
        return mainDiagonal || antiDiagonal;
    }

    private static List<Integer> allCells() {
        List<Integer> cells = new ArrayList<>(ObjectLocationConfig.GRID_CELL_COUNT);
        for (int i = 0; i < ObjectLocationConfig.GRID_CELL_COUNT; i++) cells.add(i);
        return cells;
    }

    private static <T> void fisherYates(List<T> values, XorShift32 random) {
        for (int i = values.size() - 1; i > 0; i--) {
            Collections.swap(values, i, random.nextInt(i + 1));
        }
    }

    /** FNV-1a 32 bits UTF-8, avec débordement modulo 2^32 intentionnel. */
    public static int fnv1a32(String value) {
        int hash = 0x811C9DC5;
        for (byte octet : value.getBytes(StandardCharsets.UTF_8)) {
            hash ^= Byte.toUnsignedInt(octet);
            hash *= 0x01000193;
        }
        return hash;
    }

    /** PRNG xorshift32 ; modulo non signé volontairement partagé avec Dart. */
    public static final class XorShift32 {
        private int state;

        public XorShift32(int seed) {
            state = seed == 0 ? ObjectLocationConfig.ZERO_SEED_FALLBACK : seed;
        }

        public long nextUnsigned() {
            int value = state;
            value ^= value << 13;
            value ^= value >>> 17;
            value ^= value << 5;
            state = value;
            return Integer.toUnsignedLong(value);
        }

        public int nextInt(int bound) {
            if (bound <= 0) throw new IllegalArgumentException("bound doit être > 0");
            return (int) (nextUnsigned() % bound);
        }
    }

    private record ReservePlacement(ObjectLocationReserveSide side, int order) {
    }
}
