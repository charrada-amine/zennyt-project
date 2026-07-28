package com.zennyt.games.api.dto;

import com.zennyt.games.application.usecase.AnswerEmotionalRadarSceneUseCase;
import com.zennyt.games.application.usecase.GetEmotionalRadarScenesUseCase;
import com.zennyt.games.domain.config.EmotionalRadarProvisionalRules;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * DTO d'« Emotional Radar ».
 *
 * <p>⚠️ <b>Point de filtrage unique de la clé de correction.</b>
 * {@link SceneResponse#from} projette un {@link EmotionalRadarScene} en omettant
 * délibérément {@code expectedEmotion}, {@code expectedNuance},
 * {@code expectedIntensity} et {@code explanation}. Aucun autre chemin ne
 * sérialise une scène : c'est ici, et seulement ici, que se joue le fait que le
 * client ne connaisse jamais la réponse à l'avance.
 */
public final class EmotionalRadarDtos {

    private EmotionalRadarDtos() {
    }

    /**
     * Scène telle qu'exposée au client — <b>sans</b> la réponse attendue.
     *
     * <p>Ne jamais y ajouter de champ {@code expected*} : ce serait rendre le jeu
     * triviallement triché, la correction se faisant alors côté client.
     */
    public record SceneResponse(
        UUID id,
        int sceneOrder,
        String mediaType,
        String promptText,
        String instructionText,
        String mediaUrl,
        String altText,
        String transcript
    ) {
        public static SceneResponse from(EmotionalRadarScene s) {
            return new SceneResponse(
                s.id(), s.sceneOrder(), s.mediaType().name(),
                s.promptText(), s.instructionText(),
                s.mediaUrl(), s.altText(), s.transcript());
        }
    }

    /** Nuance proposée + son origine (maquette ou ajout provisoire). */
    public record NuanceResponse(String key, String label, String source) {
        static NuanceResponse from(EmotionalRadarProvisionalRules.Nuance n) {
            return new NuanceResponse(n.key(), n.label(), n.source().name());
        }
    }

    /** Une famille et ses nuances sélectionnables. */
    public record EmotionOptionsResponse(String emotion, List<NuanceResponse> nuances) {
    }

    /** Réponse de {@code GET .../emotional-radar/scenes}. */
    public record SceneListResponse(
        int totalScenes,
        int maxPoints,
        List<EmotionOptionsResponse> emotions,
        List<SceneResponse> scenes
    ) {
        public static SceneListResponse from(GetEmotionalRadarScenesUseCase.Result result) {
            List<EmotionOptionsResponse> emotions =
                result.nuances().entrySet().stream()
                    .map(EmotionalRadarDtos::toEmotionOptions)
                    .toList();
            return new SceneListResponse(
                result.scenes().size(),
                result.maxPoints(),
                emotions,
                result.scenes().stream().map(SceneResponse::from).toList());
        }
    }

    private static EmotionOptionsResponse toEmotionOptions(
            Map.Entry<BasicEmotion, List<EmotionalRadarProvisionalRules.Nuance>> entry) {
        return new EmotionOptionsResponse(
            entry.getKey().name(),
            entry.getValue().stream().map(NuanceResponse::from).toList());
    }

    /** Corps de {@code POST .../scenes/{sceneId}/answers}. */
    public record AnswerRequest(
        @NotNull BasicEmotion selectedEmotion,
        @NotBlank String selectedNuance,
        @NotNull @Min(1) @Max(5) Integer selectedIntensity
    ) {
    }

    /**
     * Feedback affiché après validation. C'est le <b>seul</b> DTO qui divulgue la
     * réponse attendue — et uniquement pour la scène que le joueur vient de valider.
     */
    public record FeedbackResponse(
        boolean correct,
        String expectedEmotion,
        String expectedNuance,
        int suggestedIntensity,
        String explanation,
        int emotionPoints,
        int nuancePoints,
        int intensityPoints,
        int scenePoints,
        int totalPoints,
        int answeredScenes
    ) {
        public static FeedbackResponse from(AnswerEmotionalRadarSceneUseCase.Result r) {
            EmotionalRadarAnswer a = r.answer();
            return new FeedbackResponse(
                a.correct(),
                a.expectedEmotion().name(),
                a.expectedNuance(),
                a.expectedIntensity(),
                r.explanation(),
                a.emotionPoints(),
                a.nuancePoints(),
                a.intensityPoints(),
                a.scenePoints(),
                r.totalPoints(),
                r.answeredScenes());
        }
    }
}
