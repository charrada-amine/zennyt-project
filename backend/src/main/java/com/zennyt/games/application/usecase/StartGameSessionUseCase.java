package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.StartGameSessionCommand;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.repository.GameSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Use case : démarrer une session de jeu.
 *
 * <p>Couche fine d'orchestration : crée l'agrégat et le persiste. Aucune
 * logique métier ici (elle est dans l'agrégat {@link GameSession}).
 */
@Service
public class StartGameSessionUseCase {

    private final GameSessionRepository repository;

    public StartGameSessionUseCase(GameSessionRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public GameSession execute(StartGameSessionCommand command) {
        GameSession session = GameSession.start(command.playerId(), command.gameType());
        return repository.save(session);
    }
}
