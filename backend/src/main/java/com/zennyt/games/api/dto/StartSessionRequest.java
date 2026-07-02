package com.zennyt.games.api.dto;

import com.zennyt.games.domain.vo.GameType;
import jakarta.validation.constraints.NotNull;

/** DTO de requête : démarrer une session (le joueur vient du JWT). */
public record StartSessionRequest(
    @NotNull GameType gameType
) {}
