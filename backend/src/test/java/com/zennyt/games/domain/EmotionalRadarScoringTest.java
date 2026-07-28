package com.zennyt.games.domain;

import com.zennyt.games.domain.config.EmotionalRadarConfig;
import com.zennyt.games.domain.config.EmotionalRadarProvisionalRules;
import com.zennyt.games.domain.service.EmotionalRadarScoringService;
import com.zennyt.games.domain.vo.BasicEmotion;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import com.zennyt.games.domain.vo.EmotionalRadarMetrics;
import com.zennyt.games.domain.vo.EmotionalRadarReport;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.EmotionalRadarSceneMetric;
import com.zennyt.games.domain.vo.SceneMediaType;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Barème « Emotional Radar » — Java pur, sans Spring.
 *
 * <p>Verrouille le barème de la planche « Developer handoff » et, surtout, la
 * propriété anti-triche : le score ne dépend que des réponses notées serveur.
 */
class EmotionalRadarScoringTest {

    private final EmotionalRadarScoringService scoring = new EmotionalRadarScoringService();
    private static final UUID SESSION = UUID.randomUUID();

    /** Scène 1 du handoff : dialogue → Sadness / Disappointment / 3. */
    private static EmotionalRadarScene scene1() {
        return new EmotionalRadarScene(
            UUID.randomUUID(), 1, SceneMediaType.DIALOGUE,
            "Friend: I am sorry, I have to cancel tonight.",
            "Observe the situation, then identify the emotional pattern.",
            null, null, null, null,
            BasicEmotion.SADNESS, "DISAPPOINTMENT", 3,
            "Disappointment belongs to the sadness family.");
    }

    private EmotionalRadarAnswer grade(EmotionalRadarScene scene, BasicEmotion emotion,
                                       String nuance, int intensity) {
        return scoring.grade(SESSION, scene, emotion, nuance, intensity, Instant.now());
    }

    @Test
    @DisplayName("Réponse parfaite : 3 + 4 + 2 = 9 points")
    void perfectAnswerScoresNine() {
        EmotionalRadarAnswer a = grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3);

        assertThat(a.emotionPoints()).isEqualTo(3);
        assertThat(a.nuancePoints()).isEqualTo(4);
        assertThat(a.intensityPoints()).isEqualTo(2);
        assertThat(a.scenePoints()).isEqualTo(9);
        assertThat(a.correct()).isTrue();
    }

    @Test
    @DisplayName("Mauvaise famille : émotion ET nuance à 0 (la nuance ne peut pas être juste)")
    void wrongFamilyScoresZeroOnBothLabels() {
        // Scène 2 du handoff : le joueur répond Joy / Excitement / 2 au lieu de Fear / Anxiety / 4.
        EmotionalRadarAnswer a = grade(scene1(), BasicEmotion.JOY, "EXCITEMENT", 3);

        assertThat(a.emotionPoints()).isZero();
        assertThat(a.nuancePoints()).isZero();
        // L'intensité reste évaluée indépendamment : elle était juste.
        assertThat(a.intensityPoints()).isEqualTo(2);
        assertThat(a.scenePoints()).isEqualTo(2);
        assertThat(a.correct()).isFalse();
    }

    @Test
    @DisplayName("Intensité : écart 0 → 2 pts · écart 1 → 1 pt · écart ≥ 2 → 0")
    void intensityIsScoredByDistance() {
        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3).intensityPoints())
            .isEqualTo(2);
        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 4).intensityPoints())
            .isEqualTo(1);
        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 2).intensityPoints())
            .isEqualTo(1);
        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 5).intensityPoints())
            .isZero();
        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 1).intensityPoints())
            .isZero();
    }

    @Test
    @DisplayName("3 scènes parfaites → 27/27, le total annoncé par la maquette")
    void threePerfectScenesScoreTwentySeven() {
        List<EmotionalRadarAnswer> answers = List.of(
            grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3),
            grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3),
            grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3));

        Score score = scoring.score(answers);

        assertThat(score.rawPoints()).isEqualTo(27);
        assertThat(score.maxPoints()).isEqualTo(27);
        assertThat(score.normalized()).isEqualTo(100.0);
    }

    @Test
    @DisplayName("Le bonus de gradient est désactivé : jamais plus de 9 points par scène")
    void gradientBonusStaysDisabled() {
        // Les deux totaux de la maquette (27 pour 3 scènes, 135 pour 15) n'existent
        // que si une scène vaut 9. Activer le bonus les casserait tous les deux.
        assertThat(EmotionalRadarConfig.GRADIENT_BONUS_ENABLED).isFalse();
        assertThat(EmotionalRadarConfig.POINTS_PER_SCENE).isEqualTo(9);
        assertThat(EmotionalRadarConfig.maxPointsFor(3)).isEqualTo(27);
        assertThat(EmotionalRadarConfig.maxPointsFor(15)).isEqualTo(135);

        assertThat(grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3).scenePoints())
            .isEqualTo(EmotionalRadarConfig.POINTS_PER_SCENE);
    }

    @Test
    @DisplayName("Une nuance étrangère à la famille choisie est rejetée")
    void nuanceMustBelongToSelectedFamily() {
        // Sans ce contrôle, un client pourrait envoyer la nuance attendue sous une
        // autre famille et grappiller les points de nuance.
        assertThatThrownBy(() -> grade(scene1(), BasicEmotion.JOY, "DISAPPOINTMENT", 3))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("inconnue");
    }

    @Test
    @DisplayName("Une intensité hors de l'échelle 1–5 est rejetée")
    void intensityOutOfScaleIsRejected() {
        assertThatThrownBy(() -> grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 0))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 6))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("Anti-triche : le score ignore totalement les métriques du client")
    void scoreIgnoresClientSubmittedMetrics() {
        // Le joueur a réellement obtenu 2 points (bonne intensité seulement).
        List<EmotionalRadarAnswer> graded =
            List.of(grade(scene1(), BasicEmotion.JOY, "EXCITEMENT", 3));

        // Il soumet ensuite des métriques fabriquées : elles ne portent AUCUNE
        // réponse, donc il n'existe même pas de champ à falsifier pour gagner des points.
        EmotionalRadarMetrics forged = new EmotionalRadarMetrics(List.of(
            new EmotionalRadarSceneMetric(UUID.randomUUID(), 10, true, true, false)));

        Score score = scoring.score(graded);

        assertThat(score.rawPoints()).isEqualTo(2);
        assertThat(score.maxPoints()).isEqualTo(9);
        // Les métriques n'entrent que dans les indicateurs comportementaux.
        assertThat(scoring.report(graded, forged).averageResponseTimeMs()).isEqualTo(10);
    }

    @Test
    @DisplayName("Sans aucune scène validée, le score est refusé plutôt que valant 0")
    void scoreRequiresAtLeastOneGradedAnswer() {
        assertThatThrownBy(() -> scoring.score(List.of()))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("Indicateurs : justesse par critère et confusions relevées")
    void reportDerivesAccuracyAndConfusions() {
        List<EmotionalRadarAnswer> answers = List.of(
            grade(scene1(), BasicEmotion.SADNESS, "DISAPPOINTMENT", 3),  // tout juste
            grade(scene1(), BasicEmotion.JOY, "EXCITEMENT", 5));         // tout faux

        EmotionalRadarMetrics metrics = new EmotionalRadarMetrics(List.of(
            new EmotionalRadarSceneMetric(UUID.randomUUID(), 5000, false, false, false),
            new EmotionalRadarSceneMetric(UUID.randomUUID(), 9000, true, false, false)));

        EmotionalRadarReport report = scoring.report(answers, metrics);

        assertThat(report.scenesPlayed()).isEqualTo(2);
        assertThat(report.emotionAccuracyPercent()).isEqualTo(50.0);
        assertThat(report.nuanceAccuracyPercent()).isEqualTo(50.0);
        // Intensité : 2 pts obtenus sur 4 possibles.
        assertThat(report.intensityCalibrationPercent()).isEqualTo(50.0);
        assertThat(report.averageResponseTimeMs()).isEqualTo(7000);
        assertThat(report.helpOpenedCount()).isEqualTo(1);
        assertThat(report.confusedEmotions())
            .containsExactly(new EmotionalRadarReport.Confusion(
                BasicEmotion.SADNESS, BasicEmotion.JOY));
    }

    @Test
    @DisplayName("Accessibilité : une scène IMAGE sans équivalent textuel est refusée")
    void mediaSceneRequiresTextAlternative() {
        assertThatThrownBy(() -> new EmotionalRadarScene(
            UUID.randomUUID(), 3, SceneMediaType.IMAGE,
            "A child cries alone in a quiet courtyard.", "Observe the image.",
            "https://cdn/img.png", "pid", /* altText */ null, null,
            BasicEmotion.SADNESS, "EMPATHIC_PAIN", 3, "…"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("altText");

        assertThatThrownBy(() -> new EmotionalRadarScene(
            UUID.randomUUID(), 4, SceneMediaType.VIDEO,
            "A tense exchange.", "Watch the clip.",
            "https://cdn/clip.mp4", "pid", "Alt", /* transcript */ null,
            BasicEmotion.ANGER, "IRRITATION", 3, "…"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("transcript");
    }

    @Test
    @DisplayName("Taxonomie : les nuances de la maquette sont marquées FIGMA, les ajouts PROVISIONAL")
    void figmaNuancesAreDistinguishedFromProvisionalOnes() {
        // SADNESS est entièrement fournie par l'écran « 04 Emotion Selected ».
        assertThat(EmotionalRadarProvisionalRules.nuancesFor(BasicEmotion.SADNESS))
            .allMatch(n -> n.source() == EmotionalRadarProvisionalRules.NuanceSource.FIGMA)
            .extracting(EmotionalRadarProvisionalRules.Nuance::label)
            .containsExactly("Disappointment", "Nostalgia", "Empathic pain", "Sympathy", "Guilt");

        // ANGER n'apparaît sur aucune planche : tout y est provisoire.
        assertThat(EmotionalRadarProvisionalRules.nuancesFor(BasicEmotion.ANGER))
            .isNotEmpty()
            .allMatch(n -> n.source() == EmotionalRadarProvisionalRules.NuanceSource.PROVISIONAL);

        // Les six familles de la grille sont couvertes.
        assertThat(EmotionalRadarProvisionalRules.allNuances()).hasSize(6);
    }
}
