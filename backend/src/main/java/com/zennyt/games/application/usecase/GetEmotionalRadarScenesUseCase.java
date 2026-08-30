package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.catalog.EmotionalRadarSceneCatalog;
import com.zennyt.games.domain.config.EmotionalRadarConfig;
import com.zennyt.games.domain.config.EmotionalRadarProvisionalRules;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Use case : servir les scènes d'une session « Emotional Radar ».
 *
 * <p>Renvoie les scènes <b>avec</b> leur clé de correction (VO domaine) : c'est le
 * contrôleur qui les projette dans un DTO expurgé. Cette séparation est
 * volontaire — le domaine n'a pas à connaître ce qui est publiable, et le point de
 * filtrage reste unique et auditable.
 */
@Service
public class GetEmotionalRadarScenesUseCase {

    private final EmotionalRadarSceneCatalog catalog;
    private final GameSessionRepository sessions;

    public GetEmotionalRadarScenesUseCase(EmotionalRadarSceneCatalog catalog,
                                          GameSessionRepository sessions) {
        this.catalog = catalog;
        this.sessions = sessions;
    }

    /** Scènes + taxonomie pour une session existante. */
    @Transactional(readOnly = true)
    public Result execute(UUID sessionId) {
        GameSession session = sessions.findById(sessionId)
            .orElseThrow(() -> new NotFoundException("Session introuvable : " + sessionId));

        List<EmotionalRadarScene> scenes = EmotionalRadarRuntimeSelection.select(
            session, catalog.scenes(session.runtimeSnapshot().bankId()));
        if (scenes.isEmpty()) {
            throw new IllegalStateException(
                "Aucune scène active : le catalogue Emotional Radar est vide.");
        }
        return new Result(
            scenes,
            EmotionalRadarProvisionalRules.allNuances(),
            EmotionalRadarConfig.maxPointsFor(scenes.size()));
    }

    /**
     * @param scenes    scènes actives, dans l'ordre (clé de correction incluse —
     *                  à ne jamais sérialiser telle quelle)
     * @param nuances   taxonomie émotion → nuances proposées
     * @param maxPoints total atteignable pour cette session
     */
    public record Result(List<EmotionalRadarScene> scenes,
                         Map<BasicEmotion, List<EmotionalRadarProvisionalRules.Nuance>> nuances,
                         int maxPoints) {
    }
}
