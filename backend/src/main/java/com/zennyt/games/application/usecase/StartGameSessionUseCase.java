package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.StartGameSessionCommand;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.repository.GameAdminRepository;
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
    private final GameAdminRepository adminRepository;

    public StartGameSessionUseCase(GameSessionRepository repository,
                                   GameAdminRepository adminRepository) {
        this.repository = repository;
        this.adminRepository = adminRepository;
    }

    @Transactional
    public GameSession execute(StartGameSessionCommand command) {
        GameSession session = GameSession.start(command.playerId(), command.gameType(),
            adminRepository.runtimeSnapshot(command.gameType()));
        return repository.save(session);
    }
}
