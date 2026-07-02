package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.Attempt;
import com.zennyt.games.domain.model.GameSession;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTO de réponse : état complet d'une session avec son score composite. */
public record GameSessionResponse(
    UUID id,
    UUID playerId,
    String gameType,
    String status,
    int compositeRaw,
    int compositeMax,
    double normalized,
    List<AttemptResponse> attempts,
    Instant startedAt,
    Instant completedAt
) {
    /** Résultat d'un mini-jeu au sein de la session. */
    public record AttemptResponse(String miniGame, ScoreResponse score, Instant recordedAt) {
        static AttemptResponse from(Attempt a) {
            return new AttemptResponse(
                a.miniGame().name(), ScoreResponse.from(a.score()), a.recordedAt());
        }
    }

    public static GameSessionResponse from(GameSession s) {
        return new GameSessionResponse(
            s.id(), s.playerId(), s.gameType().name(), s.status().name(),
            s.compositeRaw(), s.compositeMax(), s.normalizedScore(),
            s.attempts().stream().map(AttemptResponse::from).toList(),
            s.startedAt(), s.completedAt());
    }
}
