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
            complete();
        }
        // F14 — un événement à CHAQUE mini-jeu, pas seulement à complétion totale.
        // Avant, une session partielle n'émettait rien du tout : pas de projection, pas
        // de score. Le CdC §3.3 prévoit l'inverse — la donnée partielle arrive avec une
        // décote de couverture, elle ne disparaît pas. Le listener fait un upsert par
        // (candidat, module) : chaque émission remplace la précédente par une mieux
        // couverte, jusqu'à 100 % à la complétion.
        publishResult(scoring);
    }

    private void complete() {
        this.status = SessionStatus.COMPLETED;
        this.completedAt = Instant.now();
    }

    private void publishResult(PlanifikScoringService scoring) {
        double played = playedNormalizedScore();
        registerEvent(GameResultRecordedEvent.of(
            id, playerId, gameType,
            compositeRaw(), compositeMax(), played, coverageRatio(),
            scoring.interpretGlobal(gameType, compositeRaw(), played)));
    }

    /**
     * Part des mini-jeux jouables du module effectivement jouée (0-100) — la
     * couverture au sens du CdC Fit Score v3 §3.3. Distincte du score : elle dit
     * combien du module a été mesuré, pas à quel point il a été réussi.
     */
    public int coverageRatio() {
        int expected = expectedMiniGames().size();
        if (expected == 0) return 0;
        return Math.min(100, Math.round(attempts.size() * 100f / expected));
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

    /**
     * Score ramené sur 100 <b>de ce qui a réellement été joué</b> — et non du module
     * complet comme {@link #normalizedScore()}.
     *
     * <p>F14 — c'est cette valeur qui part dans l'événement, jamais {@code normalizedScore()}.
     * Sur une session partielle, {@code normalizedScore()} divise par le maximum du module
     * entier : un joueur ayant parfaitement réussi 1 des 3 mini-jeux de Planifik obtiendrait
     * 33/100. Couplé à une couverture de 33 %, le Fit Score appliquerait 33 × 0,33 = 11 — la
     * même incomplétude comptée deux fois. La couverture porte l'incomplétude ; le score
     * doit porter la seule performance.
     *
     * <p>À complétion totale, {@code compositeMax()} vaut exactement la somme des maximums
     * enregistrés : les deux valeurs coïncident, et le comportement existant est inchangé.
     */
    public double playedNormalizedScore() {
        int recordedMax = attempts.stream().mapToInt(a -> a.score().maxPoints()).sum();
        return recordedMax == 0 ? 0.0 : compositeRaw() * 100.0 / recordedMax;
    }

    public UUID id() { return id; }
    public UUID playerId() { return playerId; }
    public GameType gameType() { return gameType; }
    public SessionStatus status() { return status; }
    public List<Attempt> attempts() { return Collections.unmodifiableList(attempts); }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
}
