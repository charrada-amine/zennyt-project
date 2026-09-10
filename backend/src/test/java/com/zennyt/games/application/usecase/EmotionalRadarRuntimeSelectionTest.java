package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.model.GameRuntimeSnapshot;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.SceneMediaType;
import com.zennyt.games.domain.vo.SessionStatus;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class EmotionalRadarRuntimeSelectionTest {
    private static final UUID SESSION_ID = UUID.fromString("00000000-0000-4000-8000-000000000123");

    @Test
    void limitsScenesWithoutChangingTheirScoreKeys() {
        GameSession session = session(Map.of("sceneCount", 2, "orderMode", "SEQUENTIAL"));

        List<EmotionalRadarScene> selected = EmotionalRadarRuntimeSelection.select(
            session, List.of(scene(1), scene(2), scene(3)));

        assertEquals(List.of(1, 2), selected.stream().map(EmotionalRadarScene::sceneOrder).toList());
        assertEquals(BasicEmotion.JOY, selected.getFirst().expectedEmotion());
    }

    @Test
    void shuffledOrderIsStableForThePersistedSessionId() {
        GameSession session = session(Map.of("sceneCount", 3, "orderMode", "SHUFFLED"));
        List<EmotionalRadarScene> catalog = List.of(scene(1), scene(2), scene(3));

        List<UUID> first = EmotionalRadarRuntimeSelection.select(session, catalog)
            .stream().map(EmotionalRadarScene::id).toList();
        List<UUID> second = EmotionalRadarRuntimeSelection.select(session, catalog)
            .stream().map(EmotionalRadarScene::id).toList();

        assertEquals(first, second);
    }

    private static GameSession session(Map<String, Object> settings) {
        return GameSession.rehydrate(SESSION_ID, UUID.randomUUID(), GameType.EMOTIONAL_REGULATION,
            SessionStatus.IN_PROGRESS, List.of(), Instant.EPOCH, null, null,
            new GameRuntimeSnapshot(1, null, settings, Map.of()));
    }

    private static EmotionalRadarScene scene(int order) {
        return new EmotionalRadarScene(new UUID(0, order), order, SceneMediaType.DIALOGUE,
            "Prompt " + order, "Instruction", null, null, null, null,
            BasicEmotion.JOY, "TRIUMPH", 3, "Explanation");
    }
}
