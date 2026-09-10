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

    @Column(name = "runtime_settings_version")
    private Integer runtimeSettingsVersion;

    @Column(name = "runtime_modifiers_version")
    private Integer runtimeModifiersVersion;

    @Column(name = "runtime_settings", nullable = false, columnDefinition = "text")
    private String runtimeSettings;

    @Column(name = "runtime_modifiers", nullable = false, columnDefinition = "text")
    private String runtimeModifiers;

    @Column(name = "runtime_bank_id")
    private UUID runtimeBankId;

    @Column(name = "runtime_bank_code", length = 64)
    private String runtimeBankCode;

    @Column(name = "runtime_bank_version")
    private Integer runtimeBankVersion;

    @Column(name = "runtime_bank_content_type", length = 32)
    private String runtimeBankContentType;

    protected GameSessionEntity() { } // requis par JPA

    public GameSessionEntity(UUID id, UUID playerId, GameType gameType, SessionStatus status,
                             List<AttemptEmbeddable> attempts, Instant startedAt, Instant completedAt,
                             String decisionFormCode, Integer runtimeSettingsVersion,
                             Integer runtimeModifiersVersion, String runtimeSettings,
                             String runtimeModifiers, UUID runtimeBankId,
                             String runtimeBankCode, Integer runtimeBankVersion,
                             String runtimeBankContentType) {
        this.id = id;
        this.playerId = playerId;
        this.gameType = gameType;
        this.status = status;
        this.attempts = new ArrayList<>(attempts);
        this.startedAt = startedAt;
        this.completedAt = completedAt;
        this.decisionFormCode = decisionFormCode;
        this.runtimeSettingsVersion = runtimeSettingsVersion;
        this.runtimeModifiersVersion = runtimeModifiersVersion;
        this.runtimeSettings = runtimeSettings;
        this.runtimeModifiers = runtimeModifiers;
        this.runtimeBankId = runtimeBankId;
        this.runtimeBankCode = runtimeBankCode;
        this.runtimeBankVersion = runtimeBankVersion;
        this.runtimeBankContentType = runtimeBankContentType;
    }

    public UUID getId() { return id; }
    public UUID getPlayerId() { return playerId; }
    public GameType getGameType() { return gameType; }
    public SessionStatus getStatus() { return status; }
    public List<AttemptEmbeddable> getAttempts() { return attempts; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public String getDecisionFormCode() { return decisionFormCode; }
    public Integer getRuntimeSettingsVersion() { return runtimeSettingsVersion; }
    public Integer getRuntimeModifiersVersion() { return runtimeModifiersVersion; }
    public String getRuntimeSettings() { return runtimeSettings; }
    public String getRuntimeModifiers() { return runtimeModifiers; }
    public UUID getRuntimeBankId() { return runtimeBankId; }
    public String getRuntimeBankCode() { return runtimeBankCode; }
    public Integer getRuntimeBankVersion() { return runtimeBankVersion; }
    public String getRuntimeBankContentType() { return runtimeBankContentType; }
}
