package com.zennyt.games.api;

import com.zennyt.games.api.dto.GameSessionResponse;
import com.zennyt.games.api.dto.StartSessionRequest;
import com.zennyt.games.api.dto.SubmitResultRequest;
import com.zennyt.games.application.command.StartGameSessionCommand;
import com.zennyt.games.application.command.SubmitGameResultCommand;
import com.zennyt.games.application.usecase.StartGameSessionUseCase;
import com.zennyt.games.application.usecase.SubmitGameResultUseCase;
import com.zennyt.games.domain.model.GameSession;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Contrôleur REST des jeux sérieux.
 *
 * <p>Couche fine : traduit la requête HTTP en commande applicative, délègue au
 * use case, mappe le résultat en DTO. Aucune logique métier ici. En
 * contract-first, ce contrôleur peut implémenter l'interface générée depuis
 * {@code games.openapi.yaml}.
 */
@RestController
@RequestMapping("/api/v1/games")
public class GamesController {

    private final StartGameSessionUseCase startSession;
    private final SubmitGameResultUseCase submitResult;

    public GamesController(StartGameSessionUseCase startSession,
                          SubmitGameResultUseCase submitResult) {
        this.startSession = startSession;
        this.submitResult = submitResult;
    }

    @PostMapping("/sessions")
    public ResponseEntity<GameSessionResponse> start(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody StartSessionRequest request) {

        UUID playerId = UUID.fromString(jwt.getSubject());
        GameSession session = startSession.execute(
            new StartGameSessionCommand(playerId, request.gameType()));

        return ResponseEntity.status(HttpStatus.CREATED).body(GameSessionResponse.from(session));
    }

    @PostMapping("/sessions/{sessionId}/results")
    public ResponseEntity<GameSessionResponse> submit(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SubmitResultRequest request) {

        SubmitGameResultUseCase.Outcome outcome = submitResult.execute(
            new SubmitGameResultCommand(sessionId, request.miniGame(),
                request.toMetrics(), request.toCalibration(sessionId)));

        return ResponseEntity.ok(GameSessionResponse.from(
            outcome.session(), outcome.moveFastReport(), outcome.previsionPuzzleReport()));
    }
}
