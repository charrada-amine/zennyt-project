package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.model.Attempt;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.vo.Score;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Adaptateur de persistance : implémente le port {@link GameSessionRepository}
 * via Spring Data JPA.
 *
 * <p>Rôle clé : convertir (mapper) entre l'agrégat {@code GameSession} (domaine
 * pur) et {@code GameSessionEntity} (JPA). Le domaine ne connaît jamais JPA.
 */
@Component
public class GameSessionRepositoryAdapter implements GameSessionRepository {

    private final JpaGameSessionRepository jpa;

    public GameSessionRepositoryAdapter(JpaGameSessionRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public GameSession save(GameSession session) {
        return toDomain(jpa.save(toEntity(session)));
    }

    @Override
    public Optional<GameSession> findById(UUID id) {
        return jpa.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<GameSession> findByIdForUpdate(UUID id) {
        return jpa.findByIdForUpdate(id).map(this::toDomain);
    }

    // ───────────── Mappers ─────────────
    private GameSessionEntity toEntity(GameSession s) {
        List<AttemptEmbeddable> attempts = s.attempts().stream()
            .map(a -> new AttemptEmbeddable(
                a.miniGame(), a.score().rawPoints(), a.score().maxPoints(),
                a.score().level(), a.recordedAt()))
            .toList();
        return new GameSessionEntity(
            s.id(), s.playerId(), s.gameType(), s.status(),
            attempts, s.startedAt(), s.completedAt());
    }

    private GameSession toDomain(GameSessionEntity e) {
        List<Attempt> attempts = e.getAttempts().stream()
            .map(a -> new Attempt(
                a.getMiniGame(),
                new Score(a.getRawPoints(), a.getMaxPoints(), a.getLevel()),
                a.getRecordedAt()))
            .toList();
        return GameSession.rehydrate(
            e.getId(), e.getPlayerId(), e.getGameType(), e.getStatus(),
            attempts, e.getStartedAt(), e.getCompletedAt());
    }
}
