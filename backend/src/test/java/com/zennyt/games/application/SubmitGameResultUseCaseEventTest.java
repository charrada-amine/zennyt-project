package com.zennyt.games.application;

import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.application.usecase.SubmitGameResultUseCase;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.repository.DeviceCalibrationRepository;
import com.zennyt.games.domain.repository.ContinuousAttentionMetricsRepository;
import com.zennyt.games.domain.repository.CoordinationMetricsRepository;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.ObjectLocationMetricsRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Verrouille la publication de {@code GameResultRecordedEvent}.
 *
 * <p>L'événement était publié depuis l'objet renvoyé par le dépôt, qui est une
 * <b>reconstruction</b> ne portant aucun événement : rien n'était jamais publié. Le
 * symptôme était entièrement silencieux côté Games — la session passait bien COMPLETED et
 * son score était juste — mais côté Recruitment, la projection soft skills n'était jamais
 * alimentée par une partie jouée et le résumé IA correspondant jamais généré.
 *
 * <p>Le test reproduit le comportement réel de l'adaptateur : {@code save} renvoie une
 * session reconstruite. Publier depuis cette valeur fait échouer le test.
 */
class SubmitGameResultUseCaseEventTest {

    private static final UUID JOUEUR = UUID.randomUUID();

    private GameSessionRepository repository;
    private ApplicationEventPublisher eventPublisher;
    private SubmitGameResultUseCase useCase;
    private GameSession session;

    @BeforeEach
    void setUp() {
        repository = mock(GameSessionRepository.class);
        eventPublisher = mock(ApplicationEventPublisher.class);
        useCase = new SubmitGameResultUseCase(repository,
            mock(DeviceCalibrationRepository.class),
            mock(EmotionalRadarAnswerRepository.class),
            mock(ContinuousAttentionMetricsRepository.class),
            mock(CoordinationMetricsRepository.class),
            mock(ObjectLocationMetricsRepository.class),
            eventPublisher,
            mock(DecisionScenarioCatalog.class));

        session = GameSession.start(JOUEUR, GameType.MEMORY_QUEST);
        // Depuis le verrou de ligne posé par Games, le cas d'usage lit la session via
        // findByIdForUpdate : sérialiser les soumissions concurrentes d'une même session.
        when(repository.findByIdForUpdate(session.id())).thenReturn(Optional.of(session));
        // Comme GameSessionRepositoryAdapter : une session reconstruite, sans événements.
        when(repository.save(any())).thenAnswer(invocation -> reconstruire(invocation.getArgument(0)));
    }

    private static GameSession reconstruire(GameSession source) {
        return GameSession.rehydrate(source.id(), source.playerId(), source.gameType(),
            source.status(), List.copyOf(source.attempts()), source.startedAt(), source.completedAt());
    }

    private SubmitGameResultCommand commande() {
        return new SubmitGameResultCommand(session.id(), JOUEUR, MiniGame.MEMORY_QUEST_CORE,
            new MemoryQuestMetrics(7, 6, 5, 7, 8, 6, 3, true, 6, 4, true, 5, true, List.of()),
            null);
    }

    @Test
    void publieLEvenementDeFinDeSessionMemeSiLeDepotRenvoieUneReconstruction() {
        useCase.execute(commande());

        var captor = org.mockito.ArgumentCaptor.forClass(GameResultRecordedEvent.class);
        verify(eventPublisher).publishEvent(captor.capture());
        assertThat(captor.getValue().playerId()).isEqualTo(JOUEUR);
        assertThat(captor.getValue().gameType()).isEqualTo(GameType.MEMORY_QUEST);
    }

    @Test
    void nePublieQuUneSeuleFois() {
        useCase.execute(commande());

        verify(eventPublisher, times(1)).publishEvent(any(GameResultRecordedEvent.class));
    }
}
