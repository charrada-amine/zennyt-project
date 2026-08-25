package com.zennyt.games.api;

import com.zennyt.games.application.usecase.EmotionalRadarV2SessionUseCase;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EmotionalRadarV2ControllerTest {

    @Test
    void safeSnapshotAndExplicitActivationDelegateToDifferentUseCaseMethods()
            throws NoSuchMethodException {
        UUID sessionId = UUID.randomUUID();
        UUID playerId = UUID.randomUUID();
        Jwt jwt = Jwt.withTokenValue("test")
            .header("alg", "none")
            .subject(playerId.toString())
            .build();
        EmotionalRadarV2SessionUseCase useCase =
            mock(EmotionalRadarV2SessionUseCase.class);
        var emptyState = new EmotionalRadarV2SessionUseCase.State(
            15, 0, 1, 1, false, false, true, false, false,
            null, List.of(), 0, null);
        when(useCase.getState(sessionId, playerId)).thenReturn(emptyState);
        when(useCase.activateNext(sessionId, playerId)).thenReturn(emptyState);
        var controller = new EmotionalRadarV2Controller(useCase);

        assertThat(controller.state(jwt, sessionId).getBody().currentScene()).isNull();
        assertThat(controller.activateNext(jwt, sessionId).getBody().currentScene()).isNull();
        verify(useCase).getState(sessionId, playerId);
        verify(useCase).activateNext(sessionId, playerId);

        var get = EmotionalRadarV2Controller.class
            .getDeclaredMethod("state", Jwt.class, UUID.class)
            .getAnnotation(GetMapping.class);
        var post = EmotionalRadarV2Controller.class
            .getDeclaredMethod("activateNext", Jwt.class, UUID.class)
            .getAnnotation(PostMapping.class);
        assertThat(get.value()).containsExactly("/state");
        assertThat(post.value()).containsExactly("/scenes/next");
    }
}
