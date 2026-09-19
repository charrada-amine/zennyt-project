package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.SessionStatus;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Entité JPA de persistance d'une session de jeu — distincte de l'agrégat
 * {@code GameSession} pour ne pas polluer le domaine d'annotations JPA.
 */
@Entity
@Table(name = "game_sessions", schema = "games", indexes = {
    @Index(name = "idx_game_sessions_player", columnList = "player_id"),
    @Index(name = "idx_game_sessions_type_status", columnList = "game_type, status")})
@Check(name = "ck_game_sessions_decision_form", constraints = "decision_form_code IS NULL OR decision_form_code IN ('A', 'B', 'C', 'D')")
@Check(name = "ck_game_sessions_runtime_bank_content_type", constraints = "runtime_bank_content_type IS NULL"
    + " OR runtime_bank_content_type IN ('DECISION_SCENARIO', 'EMOTIONAL_RADAR_SCENE')")
@Check(name = "ck_game_sessions_runtime_bank_version", constraints = "runtime_bank_version IS NULL OR runtime_bank_version >= 1")
@Check(name = "ck_game_sessions_runtime_modifiers_version", constraints = "runtime_modifiers_version IS NULL OR runtime_modifiers_version >= 1")
@Check(name = "ck_game_sessions_runtime_settings_version", constraints = "runtime_settings_version IS NULL OR runtime_settings_version >= 1")
@Check(name = "ck_game_sessions_status", constraints = "status IN ('IN_PROGRESS', 'COMPLETED', 'ABANDONED')")
@Check(name = "ck_game_sessions_type", constraints = "game_type IN ('PLANIFIK', 'MOVE_FAST', 'MEMORY_QUEST', 'DECISION',"
    + " 'EMOTIONAL_REGULATION', 'CONTINUOUS_ATTENTION', 'VISUOMOTOR_COORDINATION', 'VISUOSPATIAL_MEMORY', 'DECISION_BEHAVIORAL')")
public class GameSessionEntity {

    @Id
    private UUID id;

    @Column(name = "player_id", nullable = false)
    private UUID playerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "game_type", nullable = false, length = 30)
    private GameType gameType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private SessionStatus status;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "game_attempts",
        schema = "games",
        joinColumns = @JoinColumn(name = "session_id"),
        // @OnDelete est refusé sur une @ElementCollection : la cascade est écrite dans la définition.
        foreignKey = @ForeignKey(name = "game_attempts_session_id_fkey", foreignKeyDefinition =
            "FOREIGN KEY (session_id) REFERENCES games.game_sessions (id) ON DELETE CASCADE"),
        // Index uniques partiels ux_*_single_valid_attempt : db/schema-complements.sql.
        indexes = @Index(name = "idx_game_attempts_session", columnList = "session_id"))
    @Check(name = "ck_game_attempts_mini_game", constraints = "mini_game IN ('OPTIMAL_PATH', 'TASK_SCHEDULING',"
        + " 'PREVISION_PUZZLE', 'MOVE_FAST_CORE', 'MEMORY_QUEST_CORE', 'DECISION_CORE', 'EMOTIONAL_RADAR_CORE',"
        + " 'REFLECTIVE_PAUSE_CORE', 'CONTINUOUS_ATTENTION_CORE', 'COORDINATION_TRACKING_CORE',"
        + " 'OBJECT_LOCATION_BINDING_CORE', 'STRATEGIC_CHOICES_CORE', 'BART_CORE', 'INFORMATION_SAMPLING_CORE')")
    @Check(name = "ck_game_attempts_points", constraints = "raw_points >= 0 AND max_points > 0 AND raw_points <= max_points")
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

    @ColumnDefault("'{}'")
    @Column(name = "runtime_settings", nullable = false, length = Length.LONG32)
    private String runtimeSettings;

    @ColumnDefault("'{}'")
    @Column(name = "runtime_modifiers", nullable = false, length = Length.LONG32)
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
