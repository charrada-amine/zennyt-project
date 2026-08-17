package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.SessionStatus;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Entité JPA de persistance d'une session de jeu — distincte de l'agrégat
 * {@code GameSession} pour ne pas polluer le domaine d'annotations JPA.
 */
@Entity
@Table(name = "game_sessions", schema = "games")
public class GameSessionEntity {

    @Id
    private UUID id;

    @Column(name = "player_id", nullable = false)
    private UUID playerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "game_type", nullable = false)
    private GameType gameType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SessionStatus status;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "game_attempts",
        schema = "games",
        joinColumns = @JoinColumn(name = "session_id"))
    private List<AttemptEmbeddable> attempts = new ArrayList<>();

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    /** Forme de passation « Je Décide » (A/B/C/D) ; null hors session DECISION. */
    @Column(name = "decision_form_code", length = 1)
    private String decisionFormCode;

    protected GameSessionEntity() { } // requis par JPA

    public GameSessionEntity(UUID id, UUID playerId, GameType gameType, SessionStatus status,
                             List<AttemptEmbeddable> attempts, Instant startedAt, Instant completedAt,
                             String decisionFormCode) {
        this.id = id;
        this.playerId = playerId;
        this.gameType = gameType;
        this.status = status;
        this.attempts = new ArrayList<>(attempts);
        this.startedAt = startedAt;
        this.completedAt = completedAt;
        this.decisionFormCode = decisionFormCode;
    }

    public UUID getId() { return id; }
    public UUID getPlayerId() { return playerId; }
    public GameType getGameType() { return gameType; }
    public SessionStatus getStatus() { return status; }
    public List<AttemptEmbeddable> getAttempts() { return attempts; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public String getDecisionFormCode() { return decisionFormCode; }
}
