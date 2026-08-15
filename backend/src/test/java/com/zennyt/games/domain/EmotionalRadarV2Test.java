package com.zennyt.games.domain;

import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.service.AdaptiveDifficultyService;
import com.zennyt.games.domain.service.DistractorSelectionService;
import com.zennyt.games.domain.service.EmotionalRadarV2ReportService;
import com.zennyt.games.domain.service.RadarGameScoreService;
import com.zennyt.games.domain.service.SemanticDistanceModel;
import com.zennyt.games.domain.service.ThetaIrtService;
import com.zennyt.games.domain.service.ValenceArousalDistanceModel;
import com.zennyt.games.domain.vo.DifficultyLevel;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.EmotionalRadarV2Report;
import com.zennyt.games.domain.vo.RadarSceneOutcome;
import com.zennyt.games.infrastructure.catalog.JsonEmotionReferential;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Vérifie le cœur de domaine « Emotional Radar v2 » : référentiel 45 émotions,
 * distance sémantique, sélection de distracteurs par niveau, difficulté adaptative,
 * score « jeu » et couche theta isolée.
 */
class EmotionalRadarV2Test {

    private final JsonEmotionReferential referential = new JsonEmotionReferential();
    private final SemanticDistanceModel distance = new ValenceArousalDistanceModel();

    @Test
    @DisplayName("Le référentiel charge 45 émotions (18/20/3/4)")
    void referentielCharge45() {
        assertThat(referential.size()).isEqualTo(EmotionalRadarV2Config.EMOTION_POOL_SIZE);
        assertThat(referential.byKey("JOY")).isPresent();
        assertThat(referential.byKey("GRATITUDE")).isPresent();
    }

    @Test
    @DisplayName("Distance sémantique : joie/peur >> joie/amusement")
    void distanceCoherente() {
        EmotionDefinition joy = referential.byKey("JOY").orElseThrow();
        EmotionDefinition fear = referential.byKey("FEAR").orElseThrow();
        EmotionDefinition amusement = referential.byKey("AMUSEMENT").orElseThrow();
        assertThat(distance.distance(joy, fear)).isGreaterThan(distance.distance(joy, amusement));
    }

    @Test
    @DisplayName("Sélection de distracteurs : N choix, la bonne réponse incluse, L4 plus proche que L1")
    void distracteursParNiveau() {
        DistractorSelectionService selector = new DistractorSelectionService(referential, distance);
        EmotionDefinition target = referential.byKey("ANXIETY").orElseThrow();

        DifficultyLevel l1 = EmotionalRadarV2Config.level(1); // 6 choix, distance élevée
        DifficultyLevel l4 = EmotionalRadarV2Config.level(4); // 9 choix, distance faible

        List<EmotionDefinition> c1 = selector.buildChoices(target, l1, 42L);
        List<EmotionDefinition> c4 = selector.buildChoices(target, l4, 42L);

        assertThat(c1).hasSize(6).contains(target);
        assertThat(c4).hasSize(9).contains(target);
        // L4 vise des émotions plus proches → difficulté (proximité) plus grande qu'en L1.
        assertThat(selector.sceneDifficulty(target, c4))
            .isLessThan(selector.sceneDifficulty(target, c1));
    }

    @Test
    @DisplayName("Difficulté adaptative : >70% monte, <40% descend, fenêtre trop courte reste")
    void difficulteAdaptative() {
        AdaptiveDifficultyService adaptive = new AdaptiveDifficultyService();
        assertThat(adaptive.nextLevel(1, List.of(true, true))).isEqualTo(1); // fenêtre < 3
        assertThat(adaptive.nextLevel(1, List.of(true, true, true))).isEqualTo(2); // 100% > 70%
        assertThat(adaptive.nextLevel(3, List.of(false, false, false))).isEqualTo(2); // 0% < 40%
        assertThat(adaptive.nextLevel(4, List.of(true, true, true, true))).isEqualTo(4); // plafond
        assertThat(adaptive.nextLevel(1, List.of(false, false))).isEqualTo(1); // plancher
    }

    @Test
    @DisplayName("Score jeu /10 et theta verrouillé (usage décisionnel interdit)")
    void scoreJeuEtThetaVerrouille() {
        List<RadarSceneOutcome> outcomes = new ArrayList<>();
        for (int i = 1; i <= 12; i++) {
            boolean correct = i % 3 != 0; // 8/12 corrects
            outcomes.add(new RadarSceneOutcome(
                i, Math.min(4, 1 + i / 4), 6, correct ? 0.5 : 0.3,
                "JOY", correct ? "JOY" : "FEAR", correct,
                correct ? 0.0 : 0.6, 1, 1, 2500, false, 3));
        }
        RadarGameScoreService game = new RadarGameScoreService();
        var score = game.score(outcomes, 4);
        assertThat(score.rawPoints()).isBetween(0, 10);
        assertThat(score.maxPoints()).isEqualTo(10);

        EmotionalRadarV2ReportService reportService = new EmotionalRadarV2ReportService(
            referential, game, new ThetaIrtService());
        EmotionalRadarV2Report report = reportService.report(outcomes, 1, List.of());

        assertThat(report.totalScenes()).isEqualTo(12);
        assertThat(report.correctEmotions()).isEqualTo(8);
        assertThat(report.theta().decisionalUseAllowed()).isFalse(); // VERROUILLÉ
        assertThat(report.theta().reliabilityFlag()).isEqualTo("Provisoire"); // < 20 items
        assertThat(report.accuracyByChoiceCount()).containsKey(6);
        assertThat(report.stimulusTypePerformance()).containsKey("FACIAL");
    }
}
