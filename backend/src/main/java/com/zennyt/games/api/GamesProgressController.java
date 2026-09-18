package com.zennyt.games.api;

import com.zennyt.games.api.dto.GamesProgressResponse;
import com.zennyt.games.application.usecase.GetGamesProgressUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Progression du joueur connecté dans le catalogue des jeux (« Coverage »). */
@RestController
@RequestMapping("/api/v1/games")
public class GamesProgressController {

    private final GetGamesProgressUseCase progress;

    public GamesProgressController(GetGamesProgressUseCase progress) {
        this.progress = progress;
    }

    @GetMapping("/progress")
    public ResponseEntity<GamesProgressResponse> progress(@AuthenticationPrincipal Jwt jwt) {
        UUID playerId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(GamesProgressResponse.from(progress.execute(playerId)));
    }
}
