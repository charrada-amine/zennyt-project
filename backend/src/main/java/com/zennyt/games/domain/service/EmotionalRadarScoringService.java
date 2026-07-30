package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarConfig;
import com.zennyt.games.domain.config.EmotionalRadarProvisionalRules;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import com.zennyt.games.domain.vo.EmotionalRadarMetrics;
import com.zennyt.games.domain.vo.EmotionalRadarReport;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.Score;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Barème déterministe d'« Emotional Radar ». Java pur, rejouable.
 *
 * <p>Deux responsabilités bien séparées :
 * <ol>
 *   <li>{@link #grade} — corriger UNE scène au moment où le joueur valide ;</li>
 *   <li>{@link #score} — agréger les réponses déjà notées en un {@link Score}.</li>
 * </ol>
 *
 * <p>Le moteur ne code aucune valeur provisoire : la taxonomie des nuances et les
 * bandes d'interprétation sont lues dans {@link EmotionalRadarProvisionalRules}.
 *
 * <p><b>Parité mock ⇄ backend</b> : {@code games_mock_repository.dart} reproduit ce
 * barème à l'identique (AGENTS.md §7.7). Toute modification ici impose la même
 * modification côté mobile, dans la même PR.
 */
public final class EmotionalRadarScoringService {

    /**
     * Corrige une réponse et produit la {@link EmotionalRadarAnswer} à persister.
     *
     * <p>C'est le seul endroit où la clé de correction est comparée à la réponse du
     * joueur. Le résultat est immédiatement persistable : les points calculés ici
     * font autorité pour le score final.
     */
    public EmotionalRadarAnswer grade(UUID sessionId,
                                      EmotionalRadarScene scene,
                                      BasicEmotion selectedEmotion,
                                      String selectedNuance,
                                      int selectedIntensity,
                                      Instant answeredAt) {

        if (scene == null) {
            throw new IllegalArgumentException("scène requise");
        }
        if (selectedEmotion == null) {
            throw new IllegalArgumentException("selectedEmotion requise");
        }
        if (selectedIntensity < EmotionalRadarConfig.MIN_INTENSITY
            || selectedIntensity > EmotionalRadarConfig.MAX_INTENSITY) {
            throw new IllegalArgumentException(
                "selectedIntensity hors échelle 1–5 : " + selectedIntensity);
        }
        // La nuance doit appartenir à la famille choisie : sans ce contrôle, un
        // client pourrait envoyer la nuance attendue sous une autre famille.
        if (!EmotionalRadarProvisionalRules.isValidNuance(selectedEmotion, selectedNuance)) {
            throw new IllegalArgumentException(
                "nuance « " + selectedNuance + " » inconnue pour " + selectedEmotion);
        }

        boolean emotionOk = selectedEmotion == scene.expectedEmotion();
        boolean nuanceOk = scene.expectedNuance().equalsIgnoreCase(selectedNuance.trim());

        int emotionPoints = emotionOk ? EmotionalRadarConfig.EMOTION_POINTS : 0;
        int nuancePoints = nuanceOk ? EmotionalRadarConfig.NUANCE_POINTS : 0;
        int intensityPoints = EmotionalRadarConfig.intensityScore(
            scene.expectedIntensity(), selectedIntensity);

        int scenePoints = emotionPoints + nuancePoints + intensityPoints;

        // Bonus de gradient : neutralisé par défaut (cf. EmotionalRadarConfig).
        boolean perfect = emotionOk && nuanceOk
            && intensityPoints == EmotionalRadarConfig.INTENSITY_POINTS;
        if (EmotionalRadarConfig.GRADIENT_BONUS_ENABLED && perfect) {
            scenePoints += EmotionalRadarConfig.GRADIENT_BONUS_POINTS;
        }

        return new EmotionalRadarAnswer(
            sessionId,
            scene.id(),
            scene.sceneOrder(),
            selectedEmotion,
            selectedNuance.trim(),
            selectedIntensity,
            scene.expectedEmotion(),
            scene.expectedNuance(),
            scene.expectedIntensity(),
            emotionPoints,
            nuancePoints,
            intensityPoints,
            scenePoints,
            // « Correct! » exige la bonne famille ET la bonne nuance : la carte de
            // succès de la maquette affiche les deux comme attendus.
            emotionOk && nuanceOk,
            answeredAt);
    }

    /**
     * Score du mini-jeu à partir des réponses <b>déjà notées et persistées</b>.
     *
     * <p>Ne prend délibérément aucune donnée du client : c'est ce qui rend le
     * score infalsifiable côté mobile.
     */
    public Score score(List<EmotionalRadarAnswer> answers) {
        if (answers == null || answers.isEmpty()) {
            throw new IllegalArgumentException(
                "aucune scène validée : le score ne peut pas être calculé");
        }
        int raw = answers.stream().mapToInt(EmotionalRadarAnswer::scenePoints).sum();
        int max = EmotionalRadarConfig.maxPointsFor(answers.size());
        double normalized = raw * 100.0 / max;
        return new Score(raw, max, EmotionalRadarProvisionalRules.interpret(normalized));
    }

    /**
     * Indicateurs comportementaux : croise les réponses notées serveur avec les
     * mesures de temps envoyées par le client.
     */
    public EmotionalRadarReport report(List<EmotionalRadarAnswer> answers,
                                       EmotionalRadarMetrics metrics) {
        if (answers == null || answers.isEmpty()) {
            return new EmotionalRadarReport(0, 0, 0, 0, 0, 0, List.of());
        }
        int played = answers.size();

        long emotionOk = answers.stream().filter(EmotionalRadarAnswer::emotionCorrect).count();
        long nuanceOk = answers.stream().filter(EmotionalRadarAnswer::nuanceCorrect).count();

        // Calibrage d'intensité : points obtenus / points possibles sur ce critère.
        int intensityEarned = answers.stream()
            .mapToInt(EmotionalRadarAnswer::intensityPoints).sum();
        int intensityMax = played * EmotionalRadarConfig.INTENSITY_POINTS;

        List<EmotionalRadarReport.Confusion> confusions = new ArrayList<>();
        for (EmotionalRadarAnswer a : answers) {
            if (!a.emotionCorrect()) {
                confusions.add(new EmotionalRadarReport.Confusion(
                    a.expectedEmotion(), a.selectedEmotion()));
            }
        }

        return new EmotionalRadarReport(
            played,
            percent(emotionOk, played),
            percent(nuanceOk, played),
            percent(intensityEarned, intensityMax),
            metrics == null ? 0 : metrics.averageResponseTimeMs(),
            metrics == null ? 0 : metrics.helpOpenedCount(),
            confusions);
    }

    private static double percent(long numerator, long denominator) {
        if (denominator <= 0) {
            return 0;
        }
        return Math.round(numerator * 1000.0 / denominator) / 10.0;
    }
}
