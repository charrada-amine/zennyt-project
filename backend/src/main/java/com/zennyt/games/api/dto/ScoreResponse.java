package com.zennyt.games.api.dto;

import com.zennyt.games.domain.vo.Score;

/** DTO de réponse : un score noté (mini-jeu ou composite). */
public record ScoreResponse(int rawPoints, int maxPoints, double normalized, String level) {

    public static ScoreResponse from(Score s) {
        return new ScoreResponse(s.rawPoints(), s.maxPoints(), s.normalized(), s.level());
    }
}
