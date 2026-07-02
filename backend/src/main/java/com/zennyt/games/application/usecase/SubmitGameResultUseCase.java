package com.zennyt.games.application.usecase;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Use case : soumettre le résultat d'un mini-jeu.
 *
 * <p>Flux applicatif :
 * <ol>
 *   <li>charge la session ;</li>
 *   <li>calcule le score déterministe à partir des métriques (domaine) ;</li>
 *   <li>enregistre le résultat sur l'agrégat (qui se termine + émet l'événement
 *       au dernier mini-jeu) ;</li>
 *   <li>persiste, puis publie les Domain Events après commit.</li>
 * </ol>
 */
@Service
public class SubmitGameResultUseCase {

    private final GameSessionRepository repository;
    private final ApplicationEventPublisher eventPublisher;
    private final PlanifikScoringService scoring = new PlanifikScoringService();

    public SubmitGameResultUseCase(GameSessionRepository repository,
                                   ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public GameSession execute(SubmitGameResultCommand command) {
        GameSession session = repository.findById(command.sessionId())
            .orElseThrow(() -> new NotFoundException(
                "Session introuvable : " + command.sessionId()));

        Score score = computeScore(command.miniGame(), command);
        session.recordResult(command.miniGame(), score, scoring);

        GameSession saved = repository.save(session);

        // Publication des Domain Events après persistance réussie
        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearEvents();

        return saved;
    }

    /** Sélectionne le barème selon le mini-jeu. Seul OPTIMAL_PATH est implémenté. */
    private Score computeScore(MiniGame miniGame, SubmitGameResultCommand command) {
        return switch (miniGame) {
            case OPTIMAL_PATH -> scoring.scoreOptimalPath(command.metrics());
            case TASK_SCHEDULING, PREVISION_PUZZLE -> throw new IllegalArgumentException(
                "Barème non encore implémenté pour " + miniGame);
        };
    }
}
