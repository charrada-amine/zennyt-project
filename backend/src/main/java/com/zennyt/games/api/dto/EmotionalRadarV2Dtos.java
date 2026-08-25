package com.zennyt.games.api.dto;

import com.zennyt.games.application.usecase.EmotionalRadarV2SessionUseCase;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.EmotionalRadarV2Report;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;

/** DTO expurgés du parcours Emotional Radar V2. */
public final class EmotionalRadarV2Dtos {

    private EmotionalRadarV2Dtos() {
    }

    /** Le client n'envoie ni temps, ni résultat, ni difficulté. */
    public record AnswerRequest(
        @NotBlank @Size(max = 64) String selectedEmotionKey,
        @NotNull @Min(0) @Max(2) Integer selectedIntensity,
        @NotBlank @Size(max = 2000) String explanation
    ) {
    }

    public record ChoiceResponse(String key, String labelFr, String labelEn) {
        static ChoiceResponse from(EmotionDefinition emotion) {
            return new ChoiceResponse(emotion.key(), emotion.labelFr(), emotion.labelEn());
        }
    }

    /**
     * Point de filtrage anti-triche : correctEmotionKey, stimulusIntensity,
     * sceneDifficulty et tous les champs de réponse sont volontairement omis.
     */
    public record SceneResponse(
        int sceneOrder,
        int level,
        int choicesCount,
        List<ChoiceResponse> choices,
        String mediaStatus,
        String mediaUrl,
        String contextualCaption,
        int maxResponseTimeMs,
        int remainingResponseTimeMs,
        int impulsiveThresholdMs
    ) {
        static SceneResponse from(RadarV2SceneAssignment scene,
                                  List<EmotionDefinition> choices,
                                  int remainingResponseTimeMs) {
            return new SceneResponse(
                scene.sceneOrder(), scene.level(), scene.choiceKeys().size(),
                choices.stream().map(ChoiceResponse::from).toList(),
                scene.mediaStatus().name(), scene.mediaUrl(), scene.contextualCaption(),
                EmotionalRadarV2Config.MAX_RESPONSE_TIME_MS,
                remainingResponseTimeMs,
                EmotionalRadarV2Config.MIN_IMPULSIVE_TIME_MS);
        }
    }

    public record ReportResponse(
        int totalScenes,
        int startingLevel,
        int finalLevel,
        List<String> levelTransitions,
        int correctEmotions,
        double emotionAccuracyPercent,
        Map<Integer, Double> accuracyByLevel,
        Map<Integer, Double> accuracyByChoiceCount,
        Map<String, Double> accuracyBySemanticDistance,
        boolean semanticDistanceScoringAvailable,
        double semanticProximityErrorScore,
        double intensityMatchPercent,
        Map<String, Integer> intensityErrorDirection,
        Map<String, Double> accuracyByStimulusIntensity,
        Map<String, Double> stimulusTypePerformance,
        boolean stimulusTypeScoringAvailable,
        Double justificationScore,
        boolean justificationScoringAvailable,
        int averageResponseTimeMs,
        double impulsiveResponsesPercent,
        int radarEmotionScore,
        String emotionalLevel
    ) {
        static ReportResponse from(EmotionalRadarV2Report report) {
            return new ReportResponse(
                report.totalScenes(), report.startingLevel(), report.finalLevel(),
                report.levelTransitions(), report.correctEmotions(),
                report.emotionAccuracyPercent(), report.accuracyByLevel(),
                report.accuracyByChoiceCount(), report.accuracyBySemanticDistance(),
                report.semanticDistanceScoringAvailable(),
                report.semanticProximityErrorScore(), report.intensityMatchPercent(),
                report.intensityErrorDirection(), report.accuracyByStimulusIntensity(),
                report.stimulusTypePerformance(), report.stimulusTypeScoringAvailable(),
                report.justificationScore(),
                report.justificationScoringAvailable(), report.averageResponseTimeMs(),
                report.impulsiveResponsesPercent(), report.radarEmotionScore(),
                report.emotionalLevel());
        }
    }

    public record StateResponse(
        int totalScenes,
        int answeredScenes,
        int startingLevel,
        int currentLevel,
        boolean completed,
        boolean mediaLibraryReady,
        boolean scoringProvisional,
        boolean fitScorePublished,
        boolean measurementAvailable,
        SceneResponse currentScene,
        ReportResponse report
    ) {
        public static StateResponse from(EmotionalRadarV2SessionUseCase.State state) {
            return new StateResponse(
                state.totalScenes(), state.answeredScenes(), state.startingLevel(),
                state.currentLevel(), state.completed(), state.mediaLibraryReady(),
                state.scoringProvisional(), state.fitScorePublished(),
                state.measurementAvailable(),
                state.currentScene() == null ? null
                    : SceneResponse.from(
                        state.currentScene(), state.currentChoices(),
                        state.currentSceneRemainingResponseTimeMs()),
                state.report() == null ? null : ReportResponse.from(state.report()));
        }
    }

    public record FeedbackResponse(
        int sceneOrder,
        boolean correct,
        boolean timedOut,
        int responseTimeMs,
        boolean impulsive,
        String expectedEmotionKey,
        int expectedIntensity,
        double semanticErrorDistance
    ) {
        static FeedbackResponse from(EmotionalRadarV2SessionUseCase.Feedback feedback) {
            return new FeedbackResponse(
                feedback.sceneOrder(), feedback.correct(), feedback.timedOut(),
                feedback.responseTimeMs(), feedback.impulsive(),
                feedback.expectedEmotionKey(), feedback.expectedIntensity(),
                feedback.semanticErrorDistance());
        }
    }

    public record AnswerResultResponse(
        FeedbackResponse feedback,
        StateResponse state
    ) {
        public static AnswerResultResponse from(
                EmotionalRadarV2SessionUseCase.AnswerResult result) {
            return new AnswerResultResponse(
                FeedbackResponse.from(result.feedback()), StateResponse.from(result.state()));
        }
    }
}
