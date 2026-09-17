package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.model.GamesProgress;
import com.zennyt.games.domain.repository.GameCompletionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Use case : lire la progression du joueur dans le catalogue des jeux. */
@Service
public class GetGamesProgressUseCase {

    private final GameCompletionRepository completions;

    public GetGamesProgressUseCase(GameCompletionRepository completions) {
        this.completions = completions;
    }

    @Transactional(readOnly = true)
    public GamesProgress execute(UUID playerId) {
        return completions.progressOf(playerId);
    }
}
