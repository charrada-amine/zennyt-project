package com.zennyt.games.domain;

import com.zennyt.games.domain.config.StrategicChoicesConfig;
import com.zennyt.games.domain.service.StrategicChoicesScoringService;
import com.zennyt.games.domain.vo.CopingFamily;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.StrategicChoiceAnswerMetric;
import com.zennyt.games.domain.vo.StrategicChoiceMedium;
import com.zennyt.games.domain.vo.StrategicChoiceStrategy;
import com.zennyt.games.domain.vo.StrategicChoicesMetrics;
import com.zennyt.games.domain.vo.StrategicChoicesReport;
import com.zennyt.games.infrastructure.catalog.JsonStrategicChoicesCatalog;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Barème « Choix Stratégiques » — la cotation appartient au serveur.
 */
class StrategicChoicesScoringTest {

    private final JsonStrategicChoicesCatalog catalog = new JsonStrategicChoicesCatalog();
    private final StrategicChoicesScoringService scoring =
        new StrategicChoicesScoringService(catalog);

    /** Les dix premières situations de la banque. */
    private static List<String> tenSituations() {
        List<String> ids = new ArrayList<>();
        for (int i = 1; i <= StrategicChoicesConfig.SITUATIONS_PER_JOURNEY; i++) {
            ids.add("CS-%03d".formatted(i));
        }
        return ids;
    }

    private StrategicChoicesMetrics journeyOf(StrategicChoiceStrategy strategy) {
        List<StrategicChoiceAnswerMetric> answers = new ArrayList<>();
        for (String id : tenSituations()) {
            answers.add(new StrategicChoiceAnswerMetric(
                id, strategy, 4_000, StrategicChoiceMedium.VIDEO));
        }
        return new StrategicChoicesMetrics(answers);
    }

    @Test
    @DisplayName("La banque des 80 situations est chargée avec ses huit cotations")
    void catalogLoadsTheWholeBank() {
        // 60 fiches du client + 20 situations de la proposition, dont
        // la clé découle de l'hypothèse de correspondance.
        assertThat(catalog.situationIds()).hasSize(80);
        assertThat(catalog.situationIds())
            .contains("CS-001", "CS-060", "CS-101", "CS-120");
        // CS-001 : « Assertive communication » est la réponse la mieux cotée.
        assertThat(catalog.score("CS-001", StrategicChoiceStrategy.ASSERTIVE_COMMUNICATION))
            .isEqualTo(3);
        assertThat(catalog.bestScore("CS-001")).isEqualTo(3);
        assertThat(catalog.score("CS-001", StrategicChoiceStrategy.RUMINATE)).isZero();
    }

    @Test
    @DisplayName("Ruminer ne rapporte rien : 0/30, et dix réponses contre-productives")
    void ruminatingScoresNothing() {
        StrategicChoicesReport report = scoring.report(
            journeyOf(StrategicChoiceStrategy.RUMINATE));

        assertThat(report.rawPoints()).isZero();
        assertThat(report.maxPoints()).isEqualTo(30);
        assertThat(report.counterProductiveChoices()).isEqualTo(10);
        assertThat(report.optimalChoices()).isZero();
        assertThat(report.level()).isEqualTo("Reactive strategies");
        // Sous le hasard : l'indice corrigé est planché à 0, pas négatif.
        assertThat(report.chanceCorrectedPercent()).isZero();
    }

    @Test
    @DisplayName("Le hasard vaut 0 sur l'indice corrigé, pas environ 40 % comme en brut")
    void chanceAnswersScoreZeroOnTheCorrectedIndex() {
        // Une réponse au hasard obtient, en espérance, la moyenne des huit
        // cotations de chaque fiche : c'est exactement la ligne de base. Le
        // score brut correspondant tourne autour de 40 % du maximum — d'où
        // l'inutilité du pourcentage brut pris seul.
        StrategicChoicesReport report = scoring.report(
            journeyOf(StrategicChoiceStrategy.BREATHE_PAUSE));

        double baseline = report.chanceBaseline();
        assertThat(baseline / report.maxPoints() * 100.0)
            .as("espérance du hasard, en % du maximum")
            .isBetween(30.0, 45.0);
        assertThat(StrategicChoicesConfig.chanceCorrectedPercent(
            (int) Math.round(baseline), report.maxPoints(), baseline))
            .isZero();
        assertThat(StrategicChoicesConfig.chanceCorrectedPercent(
            report.maxPoints(), report.maxPoints(), baseline))
            .isEqualTo(100.0);
    }

    @Test
    @DisplayName("Le profil de coping range les huit stratégies selon Carver")
    void copingProfileFollowsCarver() {
        // Carver regroupe ses échelles en familles sans les ordonner : le profil
        // décrit la conduite là où le score la classe.
        assertThat(scoring.report(journeyOf(StrategicChoiceStrategy.DIRECT_ACTION))
            .copingProfile())
            .containsEntry(CopingFamily.PROBLEM_FOCUSED, 10);
        assertThat(scoring.report(journeyOf(StrategicChoiceStrategy.HUMOR))
            .copingProfile())
            .containsEntry(CopingFamily.EMOTION_FOCUSED, 10);
        assertThat(scoring.report(journeyOf(StrategicChoiceStrategy.AVOID_FLEE))
            .copingProfile())
            .containsEntry(CopingFamily.DYSFUNCTIONAL, 10);

        // « Seek support » recouvre chez Carver DEUX échelles — soutien
        // émotionnel et soutien instrumental — rangées dans deux familles
        // différentes. La classer d'office fausserait le profil.
        StrategicChoicesReport soutien =
            scoring.report(journeyOf(StrategicChoiceStrategy.SEEK_SUPPORT));
        assertThat(soutien.copingProfile())
            .containsEntry(CopingFamily.UNRESOLVED, 10);
        assertThat(soutien.sharePercent(CopingFamily.UNRESOLVED)).isEqualTo(100.0);
    }

    @Test
    @DisplayName("Une stratégie constante reste sous le palier haut EN MOYENNE, pas sur chaque tirage")
    void aConstantStrategyStaysBelowTheTopBandOnAverage() {
        // Sur l'ensemble de la banque, aucune stratégie constante n'atteint
        // 60 % corrigés : la meilleure conduite constante,
        // « Assertive communication », reste autour de 41 %.
        for (StrategicChoiceStrategy strategy : StrategicChoiceStrategy.values()) {
            double total = catalog.situationIds().stream()
                .mapToInt(id -> catalog.score(id, strategy))
                .sum();
            double chance = catalog.situationIds().stream()
                .mapToDouble(catalog::chanceBaseline)
                .sum();
            int max = catalog.situationIds().size()
                * StrategicChoicesConfig.MAX_POINTS_PER_SITUATION;
            double corrige = StrategicChoicesConfig.chanceCorrectedPercent(
                (int) Math.round(total), max, chance);
            assertThat(corrige)
                .as("stratégie constante %s sur les 80 fiches, corrigée du hasard",
                    strategy)
                .isLessThan(StrategicChoicesConfig.HIGHLY_ADAPTIVE_THRESHOLD_PERCENT);
        }

        // Mais sur un TIRAGE, le palier est atteignable sans rien lire :
        // « Assertive communication » vaut 3 dans 28 fiches. Le seuil ne protège
        // donc de rien — c'est le nombre de stratégies mobilisées qui le dit.
        List<String> favorables = catalog.situationIds().stream()
            .filter(id -> catalog.score(
                id, StrategicChoiceStrategy.ASSERTIVE_COMMUNICATION) == 3)
            .limit(StrategicChoicesConfig.SITUATIONS_PER_JOURNEY)
            .toList();
        List<StrategicChoiceAnswerMetric> tirageChanceux = favorables.stream()
            .map(id -> new StrategicChoiceAnswerMetric(
                id, StrategicChoiceStrategy.ASSERTIVE_COMMUNICATION, 1_000, null))
            .toList();

        StrategicChoicesReport report =
            scoring.report(new StrategicChoicesMetrics(tirageChanceux));
        assertThat(report.rawPoints()).isEqualTo(report.maxPoints());
        assertThat(report.chanceCorrectedPercent()).isEqualTo(100.0);
        assertThat(report.level()).isEqualTo("Highly adaptive strategies");
        assertThat(report.distinctStrategiesUsed())
            .as("le seul signal qui trahit une stratégie constante")
            .isEqualTo(1);
    }

    @Test
    @DisplayName("Le maximum est dynamique : situations jouées × 3")
    void maxPointsFollowTheNumberOfSituations() {
        Score score = scoring.score(journeyOf(StrategicChoiceStrategy.RUMINATE));
        assertThat(score.maxPoints())
            .isEqualTo(StrategicChoicesConfig.SITUATIONS_PER_JOURNEY * 3);
    }

    @Test
    @DisplayName("Le rapport dit que le barème est provisoire et nomme les fiches à valider")
    void reportFlagsTheProvisionalScale() {
        // CS-002 fait partie des trois fiches que le document demande de valider.
        StrategicChoicesReport report = scoring.report(
            journeyOf(StrategicChoiceStrategy.BREATHE_PAUSE));

        assertThat(report.provisionalScoring()).isTrue();
        assertThat(report.situationsAwaitingReview()).containsExactly("CS-002");
    }

    @Test
    @DisplayName("Une situation inconnue ou dupliquée est refusée")
    void unknownOrDuplicateSituationsAreRejected() {
        List<StrategicChoiceAnswerMetric> doublon = new ArrayList<>(
            journeyOf(StrategicChoiceStrategy.BREATHE_PAUSE).answers());
        doublon.set(9, doublon.get(0));
        assertThatThrownBy(() -> new StrategicChoicesMetrics(doublon))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("dupliquée");

        List<StrategicChoiceAnswerMetric> inconnue = new ArrayList<>(
            journeyOf(StrategicChoiceStrategy.BREATHE_PAUSE).answers());
        inconnue.set(0, new StrategicChoiceAnswerMetric(
            "CS-999", StrategicChoiceStrategy.BREATHE_PAUSE, 1_000, null));
        assertThatThrownBy(() -> scoring.report(new StrategicChoicesMetrics(inconnue)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("inconnue");
    }

    @Test
    @DisplayName("Le nombre de stratégies mobilisées distingue une conduite adaptée")
    void distinctStrategiesAreCounted() {
        StrategicChoicesReport constant = scoring.report(
            journeyOf(StrategicChoiceStrategy.ASSERTIVE_COMMUNICATION));
        assertThat(constant.distinctStrategiesUsed()).isEqualTo(1);
        assertThat(constant.mostUsedStrategy())
            .isEqualTo(StrategicChoiceStrategy.ASSERTIVE_COMMUNICATION);
    }
}
