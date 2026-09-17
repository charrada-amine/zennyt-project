package com.zennyt.games.domain;

import com.zennyt.games.domain.model.CatalogGame;
import com.zennyt.games.domain.model.GamesProgress;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Couverture du catalogue affichée dans le hub (« Coverage n % »). */
class GamesProgressTest {

    @Test
    void theCatalogCountsThirteenGamesMemoryQuestTwice() {
        assertEquals(13, CatalogGame.values().length);
        assertEquals(13, new GamesProgress(Map.of()).totalGames());
    }

    @Test
    void everyMiniGameCompletesAtLeastOneCatalogGame() {
        Set<CatalogGame> reached = EnumSet.noneOf(CatalogGame.class);
        for (MiniGame miniGame : MiniGame.values()) {
            Set<CatalogGame> games = CatalogGame.completedBy(miniGame, null);
            assertFalse(games.isEmpty(), miniGame + " ne fait progresser aucun jeu");
            reached.addAll(games);
        }
        assertEquals(EnumSet.allOf(CatalogGame.class), reached,
            "chaque jeu du catalogue doit pouvoir être terminé");
    }

    @Test
    void memoryQuestModeDecidesWhichGameIsCompleted() {
        MemoryQuestMetrics images = MemoryQuestMetrics.images(
            4, 4, false, 0, 0, 0, 0, 0, 1, true, List.of());
        assertEquals(EnumSet.of(CatalogGame.MEMORY_QUEST_IMAGES),
            CatalogGame.completedBy(MiniGame.MEMORY_QUEST_CORE, images));
        // Sans métriques exploitables : mode complet, les deux jeux.
        assertEquals(
            EnumSet.of(CatalogGame.MEMORY_QUEST_DIGITS, CatalogGame.MEMORY_QUEST_IMAGES),
            CatalogGame.completedBy(MiniGame.MEMORY_QUEST_CORE, null));
    }

    @Test
    void coverageIsTheShareOfCatalogGamesCompleted() {
        assertEquals(0, new GamesProgress(Map.of()).coveragePercent());

        Map<CatalogGame, Instant> some = new EnumMap<>(CatalogGame.class);
        some.put(CatalogGame.MOVE_FAST, Instant.EPOCH);
        some.put(CatalogGame.DECISION, Instant.EPOCH);
        GamesProgress two = new GamesProgress(some);
        assertEquals(2, two.completedGames());
        assertEquals(15, two.coveragePercent(), "2 / 13 = 15,4 %");
        assertTrue(two.isCompleted(CatalogGame.MOVE_FAST));
        assertFalse(two.isCompleted(CatalogGame.OPTIMAL_PATH));

        Map<CatalogGame, Instant> all = new EnumMap<>(CatalogGame.class);
        for (CatalogGame game : CatalogGame.values()) all.put(game, Instant.EPOCH);
        assertEquals(100, new GamesProgress(all).coveragePercent());
    }
}
