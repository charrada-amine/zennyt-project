package com.zennyt.games.api;

import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.AnswerRequest;
import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.AnswerResultResponse;
import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.StateResponse;
import com.zennyt.games.application.usecase.EmotionalRadarV2SessionUseCase;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Contrôleur fin du parcours serveur Emotional Radar V2. */
@RestController
@RequestMapping("/api/v1/games/sessions/{sessionId}/emotional-radar/v2")
public class EmotionalRadarV2Controller {

    private final EmotionalRadarV2SessionUseCase sessionUseCase;

    public EmotionalRadarV2Controller(EmotionalRadarV2SessionUseCase sessionUseCase) {
        this.sessionUseCase = sessionUseCase;
    }

    @GetMapping("/state")
    public ResponseEntity<StateResponse> state(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID sessionId) {
        UUID playerId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(StateResponse.from(
            sessionUseCase.getState(sessionId, playerId)));
    }

    @PostMapping("/scenes/next")
    public ResponseEntity<StateResponse> activateNext(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID sessionId) {
        UUID playerId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(StateResponse.from(
            sessionUseCase.activateNext(sessionId, playerId)));
    }

    @PostMapping("/scenes/{sceneOrder}/answers")
    public ResponseEntity<AnswerResultResponse> answer(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID sessionId,
            @PathVariable int sceneOrder,
            @Valid @RequestBody AnswerRequest request) {
        UUID playerId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(AnswerResultResponse.from(
            sessionUseCase.answer(
                sessionId, playerId, sceneOrder,
                request.selectedEmotionKey(), request.selectedIntensity(),
                request.explanation())));
    }
}
