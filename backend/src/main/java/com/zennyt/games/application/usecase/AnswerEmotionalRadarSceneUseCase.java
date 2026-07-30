package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.catalog.EmotionalRadarSceneCatalog;
import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.service.EmotionalRadarScoringService;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Use case : corriger la réponse d'UNE scène et renvoyer le feedback.
 *
 * <p>C'est le cœur de l'anti-triche du jeu. Le client envoie son choix ; le serveur
 * le compare à la clé de correction (qu'il n'a jamais divulguée), <b>persiste</b> le
 * résultat noté, puis renvoie le feedback affiché à l'écran. À la soumission finale,
 * le score est reconstruit depuis ces lignes persistées — jamais depuis le client.
 */
@Service
public class AnswerEmotionalRadarSceneUseCase {

    private final EmotionalRadarSceneCatalog catalog;
    private final EmotionalRadarAnswerRepository answers;
    private final GameSessionRepository sessions;
    private final EmotionalRadarScoringService scoring = new EmotionalRadarScoringService();

    public AnswerEmotionalRadarSceneUseCase(EmotionalRadarSceneCatalog catalog,
                                            EmotionalRadarAnswerRepository answers,
                                            GameSessionRepository sessions) {
        this.catalog = catalog;
        this.answers = answers;
        this.sessions = sessions;
    }

    @Transactional
    public Result execute(UUID sessionId, UUID sceneId, BasicEmotion emotion,
                          String nuance, int intensity) {

        sessions.findById(sessionId)
            .orElseThrow(() -> new NotFoundException("Session introuvable : " + sessionId));

        EmotionalRadarScene scene = catalog.findById(sceneId)
            .orElseThrow(() -> new NotFoundException("Scène introuvable : " + sceneId));

        EmotionalRadarAnswer graded = scoring.grade(
            sessionId, scene, emotion, nuance, intensity, Instant.now());

        answers.save(graded);

        // Cumul recalculé depuis la base : le client n'a pas à tenir le compte,
        // et l'affichage « Score N » reste juste même après une reprise de session.
        List<EmotionalRadarAnswer> all = answers.findBySessionId(sessionId);
        int totalPoints = all.stream().mapToInt(EmotionalRadarAnswer::scenePoints).sum();

        return new Result(graded, scene.explanation(), totalPoints, all.size());
    }

    /**
     * @param answer        la réponse notée (porte les points par critère)
     * @param explanation   texte pédagogique de la scène, révélé après validation
     * @param totalPoints   cumul de la session
     * @param answeredScenes nombre de scènes validées jusqu'ici
     */
    public record Result(EmotionalRadarAnswer answer,
                         String explanation,
                         int totalPoints,
                         int answeredScenes) {
    }
}
