package com.zennyt.games.domain.model;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SessionStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * Agrégat <b>Session de jeu</b> — racine d'agrégat du contexte Games.
 *
 * <p>Toute la logique métier vit ici : on n'enregistre qu'un résultat par
 * mini-jeu, on refuse un mini-jeu étranger au type, et la session se termine
 * automatiquement (en émettant l'événement) une fois tous les mini-jeux joués.
 * L'agrégat est du Java pur : testable sans Spring ni base.
 */
public class GameSession extends AggregateRoot {

    private final UUID id;
    private final UUID playerId;
    private final GameType gameType;
    private SessionStatus status;
    private final List<Attempt> attempts;
    private final Instant startedAt;
    private Instant completedAt;

    private GameSession(UUID id, UUID playerId, GameType gameType, SessionStatus status,
                        List<Attempt> attempts, Instant startedAt, Instant completedAt) {
        this.id = id;
        this.playerId = playerId;
        this.gameType = gameType;
        this.status = status;
        this.attempts = new ArrayList<>(attempts);
        this.startedAt = startedAt;
        this.completedAt = completedAt;
    }

    /** Fabrique : démarre une nouvelle session en cours. */
    public static GameSession start(UUID playerId, GameType gameType) {
        return new GameSession(UUID.randomUUID(), playerId, gameType,
            SessionStatus.IN_PROGRESS, List.of(), Instant.now(), null);
    }

    /** Reconstruction depuis la persistance (aucun événement émis). */
    public static GameSession rehydrate(UUID id, UUID playerId, GameType gameType,
                                        SessionStatus status, List<Attempt> attempts,
                                        Instant startedAt, Instant completedAt) {
        return new GameSession(id, playerId, gameType, status, attempts, startedAt, completedAt);
    }

    /**
     * Enregistre le résultat d'un mini-jeu (score déjà calculé par le domaine).
     * Termine la session et émet {@link GameResultRecordedEvent} au dernier mini-jeu.
     *
     * <p>Le service de scoring est passé en paramètre (double dispatch) pour que
     * l'interprétation globale reste centralisée dans le domaine.
     */
    public void recordResult(MiniGame miniGame, Score score, PlanifikScoringService scoring) {
        if (status != SessionStatus.IN_PROGRESS) {
            throw new IllegalStateException("Session non ouverte : " + status);
        }
        if (!miniGame.belongsTo(gameType)) {
            throw new IllegalArgumentException(
                miniGame + " n'appartient pas au type " + gameType);
        }
        if (!miniGame.isPlayable()) {
            throw new IllegalArgumentException(
                "Mini-jeu non jouable (barème non implémenté) : " + miniGame);
        }
        if (isRecorded(miniGame)) {
            throw new IllegalStateException("Mini-jeu déjà joué : " + miniGame);
        }

        attempts.add(Attempt.of(miniGame, score));

        if (attempts.size() == expectedMiniGames().size()) {
            complete(scoring);
        }
    }

    private void complete(PlanifikScoringService scoring) {
        this.status = SessionStatus.COMPLETED;
        this.completedAt = Instant.now();
        registerEvent(GameResultRecordedEvent.of(
            id, playerId, gameType,
            compositeRaw(), compositeMax(), normalizedScore(),
            scoring.interpretGlobal(gameType, compositeRaw(), normalizedScore())));
    }

    private boolean isRecorded(MiniGame miniGame) {
        return attempts.stream().anyMatch(a -> a.miniGame() == miniGame);
    }

    /**
     * Mini-jeux attendus pour compléter une session de ce type.
     *
     * <p>Seuls les mini-jeux <b>jouables</b> ({@link MiniGame#isPlayable()}) sont
     * pris en compte : un mini-jeu dont le barème n'est pas encore implémenté
     * (ex. {@code TASK_SCHEDULING}) est temporairement exclu, sinon la session
     * ne pourrait jamais passer en {@code COMPLETED} ni émettre son événement.
     */
    public List<MiniGame> expectedMiniGames() {
        return Arrays.stream(MiniGame.values())
            .filter(m -> m.belongsTo(gameType) && m.isPlayable())
            .toList();
    }

    public int compositeRaw() {
        return attempts.stream().mapToInt(a -> a.score().rawPoints()).sum();
    }

    public int compositeMax() {
        if (status == SessionStatus.COMPLETED && attempts.size() == expectedMiniGames().size()) {
            return attempts.stream().mapToInt(a -> a.score().maxPoints()).sum();
        }
        // Pour un barème dynamique déjà joué (Move Fast / Emotional Radar), le
        // maximum réel de l'Attempt remplace le 0 déclaratif de MiniGame. Les
        // mini-jeux restants conservent leur maximum statique. Sans ce calcul,
        // Emotional Radar (27 pts) suivi de Reflective Pause (/10) produirait
        // temporairement un normalized > 100 avant le second mini-jeu.
        int recordedMax = attempts.stream()
            .mapToInt(a -> a.score().maxPoints())
            .sum();
        int remainingMax = expectedMiniGames().stream()
            .filter(expected -> !isRecorded(expected))
            .mapToInt(MiniGame::maxPoints)
            .sum();
        return recordedMax + remainingMax;
    }

    public double normalizedScore() {
        return compositeMax() == 0 ? 0.0 : compositeRaw() * 100.0 / compositeMax();
    }

    public UUID id() { return id; }
    public UUID playerId() { return playerId; }
    public GameType gameType() { return gameType; }
    public SessionStatus status() { return status; }
    public List<Attempt> attempts() { return Collections.unmodifiableList(attempts); }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
}
