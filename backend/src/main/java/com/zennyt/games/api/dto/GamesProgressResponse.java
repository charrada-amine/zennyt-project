package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.CatalogGame;
import com.zennyt.games.domain.model.GamesProgress;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;

/**
 * DTO de réponse : la progression du joueur dans le catalogue des jeux.
 *
 * @param coveragePercent part des jeux du catalogue terminés (0-100)
 * @param games           un élément par jeu du catalogue, terminé ou non
 */
public record GamesProgressResponse(int coveragePercent,
                                    int completedGames,
                                    int totalGames,
                                    List<GameProgress> games) {

    public record GameProgress(String game, boolean completed, Instant lastCompletedAt) {
    }

    public static GamesProgressResponse from(GamesProgress progress) {
        List<GameProgress> games = Arrays.stream(CatalogGame.values())
            .map(game -> new GameProgress(
                game.name(),
                progress.isCompleted(game),
                progress.lastCompletedAt().get(game)))
            .toList();
        return new GamesProgressResponse(progress.coveragePercent(),
            progress.completedGames(), progress.totalGames(), games);
    }
}
