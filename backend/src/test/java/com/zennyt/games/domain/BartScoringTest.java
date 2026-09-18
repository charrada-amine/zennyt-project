package com.zennyt.games.domain;

import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.config.BartProvisionalRules;
import com.zennyt.games.domain.service.BartScoringService;
import com.zennyt.games.domain.service.BartSequenceGenerator;
import com.zennyt.games.domain.vo.BartBalloonMetric;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.BartPhase;
import com.zennyt.games.domain.vo.BartReport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static com.zennyt.games.support.DecisionBehavioralTestFixtures.SESSION_ID;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.bartFixedStrategy;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BartScoringTest {

    private final BartScoringService scoring = new BartScoringService();
    private final BartSequenceGenerator generator = new BartSequenceGenerator();

    @Test
    @DisplayName("La stratégie fixe optimale est calculée depuis la loi : 64 pompes pour 1..128")
    void optimalFixedPumpsIs64() {
        assertThat(BartConfig.optimalFixedPumps()).isEqualTo(64);
    }

    @Test
    @DisplayName("La séquence est déterministe par session, dans 1..128, et propre à chaque session")
    void sequenceIsDeterministicAndInRange() {
        List<Integer> first = generator.generate(SESSION_ID);
        assertThat(generator.generate(SESSION_ID)).isEqualTo(first);
        assertThat(first).hasSize(BartConfig.TOTAL_BALLOON_COUNT)
            .allSatisfy(p -> assertThat(p).isBetween(1, BartConfig.MAX_PUMPS));
        assertThat(generator.generate(UUID.randomUUID())).isNotEqualTo(first);
    }

    @Test
    @DisplayName("Jouer exactement le benchmark (64 pompes) donne 100 : même chance, mêmes gains")
    void playingTheBenchmarkScores100() {
        BartReport report = scoring.report(SESSION_ID, bartFixedStrategy(SESSION_ID, 64, 200));

        assertThat(report.sessionValid()).isTrue();
        assertThat(report.totalEarnings()).isEqualTo(report.evOptimalEarnings());
        assertThat(scoring.score(report).rawPoints()).isEqualTo(100);
    }

    @Test
    @DisplayName("L'excès de prudence ET l'excès de risque coûtent des points")
    void bothCautionAndRiskAreCostly() {
        int cautious = scoring.score(scoring.report(SESSION_ID,
            bartFixedStrategy(SESSION_ID, 10, 200))).rawPoints();
        int reckless = scoring.score(scoring.report(SESSION_ID,
            bartFixedStrategy(SESSION_ID, 120, 200))).rawPoints();

        assertThat(cautious).isBetween(1, 99);
        assertThat(reckless).isLessThan(100);
    }

    @Test
    @DisplayName("Pompes moyennes ajustées = ballons notés COLLECTÉS seulement")
    void adjustedAveragePumpsIgnoresExplodedBalloons() {
        BartReport report = scoring.report(SESSION_ID, bartFixedStrategy(SESSION_ID, 64, 200));

        assertThat(report.collectedCount() + report.explosionCount()).isEqualTo(30);
        assertThat(report.adjustedAveragePumps()).isEqualTo(64.0);
    }

    @Test
    @DisplayName("Les ballons d'entraînement n'entrent ni dans les gains ni dans le benchmark")
    void practiceBalloonsAreExcluded() {
        BartReport report = scoring.report(SESSION_ID, bartFixedStrategy(SESSION_ID, 64, 200));
        int testEarnings = report.balloons().stream()
            .filter(b -> b.phase() == BartPhase.TEST).mapToInt(b -> b.earnedPoints()).sum();

        assertThat(report.testBalloonCount()).isEqualTo(BartConfig.TEST_BALLOON_COUNT);
        assertThat(report.totalEarnings()).isEqualTo(testEarnings);
    }

    @Test
    @DisplayName("Une collecte au-delà du point d'éclatement serveur est rejetée")
    void collectingPastTheExplosionPointIsRejected() {
        int point = generator.generate(SESSION_ID).get(0);
        List<BartBalloonMetric> balloons = new ArrayList<>(bartFixedStrategy(SESSION_ID, 1, 200).balloons());
        List<Long> stamps = new ArrayList<>();
        for (int p = 1; p <= point; p++) stamps.add(p * 200L);
        balloons.set(0, new BartBalloonMetric(0, BartPhase.PRACTICE, point,
            BartBalloonOutcome.COLLECTED, stamps, (point + 1) * 200L));

        assertThatThrownBy(() -> scoring.report(SESSION_ID, metrics(balloons)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("collecte impossible");
    }

    @Test
    @DisplayName("Un éclatement déclaré à une autre pompe que celle du serveur est rejeté")
    void explosionAtTheWrongPumpIsRejected() {
        int point = generator.generate(SESSION_ID).get(0);
        int wrong = point == 1 ? 2 : point - 1;
        List<BartBalloonMetric> balloons = new ArrayList<>(bartFixedStrategy(SESSION_ID, 1, 200).balloons());
        List<Long> stamps = new ArrayList<>();
        for (int p = 1; p <= wrong; p++) stamps.add(p * 200L);
        balloons.set(0, new BartBalloonMetric(0, BartPhase.PRACTICE, wrong,
            BartBalloonOutcome.EXPLODED, stamps, null));

        assertThatThrownBy(() -> scoring.report(SESSION_ID, metrics(balloons)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("incompatible avec la séquence serveur");
    }

    @Test
    @DisplayName("Collecter systématiquement sans pomper : run non engagé, invalide")
    void nonEngagedRunIsInvalid() {
        BartReport report = scoring.report(SESSION_ID, bartFixedStrategy(SESSION_ID, 0, 200));
        assertThat(report.sessionValid()).isFalse();
        assertThat(report.validityIssues()).contains("NON_ENGAGED");
    }

    @Test
    @DisplayName("Une cadence de pompe inhumaine invalide le run")
    void implausibleTimingIsInvalid() {
        BartReport report = scoring.report(SESSION_ID, bartFixedStrategy(SESSION_ID, 40, 5));
        assertThat(report.validityIssues()).contains("IMPLAUSIBLE_TIMING");
        assertThat(BartProvisionalRules.MIN_MEDIAN_INTER_PUMP_MS).isGreaterThan(5);
    }

    @Test
    @DisplayName("Une passation interrompue avant la fin est incomplète")
    void incompleteRunIsInvalid() {
        List<BartBalloonMetric> played = bartFixedStrategy(SESSION_ID, 30, 200).balloons().subList(0, 10);
        BartReport report = scoring.report(SESSION_ID,
            new BartMetrics(BartConfig.PROTOCOL_VERSION, played, false, true, 0, 0));
        assertThat(report.validityIssues()).contains("INCOMPLETE", "INTERRUPTED");
    }

    @Test
    @DisplayName("Structure : phase, horodatages et collecte d'un ballon éclaté sont contrôlés")
    void balloonStructureIsValidated() {
        assertThatThrownBy(() -> new BartBalloonMetric(0, BartPhase.TEST, 1,
            BartBalloonOutcome.COLLECTED, List.of(100L), 200L))
            .hasMessageContaining("Phase");
        assertThatThrownBy(() -> new BartBalloonMetric(2, BartPhase.TEST, 2,
            BartBalloonOutcome.COLLECTED, List.of(100L), 200L))
            .hasMessageContaining("horodatage");
        assertThatThrownBy(() -> new BartBalloonMetric(2, BartPhase.TEST, 1,
            BartBalloonOutcome.EXPLODED, List.of(100L), 200L))
            .hasMessageContaining("collecte");
        assertThatThrownBy(() -> new BartBalloonMetric(2, BartPhase.TEST, 0,
            BartBalloonOutcome.EXPLODED, List.of(), null))
            .hasMessageContaining("sans pompe");
    }

    @Test
    @DisplayName("Score provisoire : ratio arrondi half-up, plafonné à 100")
    void provisionalScoreRoundsAndCaps() {
        assertThat(BartProvisionalRules.score(1, 2).rawPoints()).isEqualTo(50);
        assertThat(BartProvisionalRules.score(2, 3).rawPoints()).isEqualTo(67);
        assertThat(BartProvisionalRules.score(500, 300).rawPoints()).isEqualTo(100);
    }

    private static BartMetrics metrics(List<BartBalloonMetric> balloons) {
        return new BartMetrics(BartConfig.PROTOCOL_VERSION, balloons, true, false, 0, 0);
    }
}
