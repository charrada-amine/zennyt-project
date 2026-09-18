package com.zennyt.games.domain;

import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.config.IstProvisionalRules;
import com.zennyt.games.domain.service.IstLayoutGenerator;
import com.zennyt.games.domain.service.IstPosteriorModel;
import com.zennyt.games.domain.service.IstScoringService;
import com.zennyt.games.domain.vo.IstBoxOpening;
import com.zennyt.games.domain.vo.IstColor;
import com.zennyt.games.domain.vo.IstCondition;
import com.zennyt.games.domain.vo.IstPhase;
import com.zennyt.games.domain.vo.IstReport;
import com.zennyt.games.domain.vo.IstTrialMetric;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static com.zennyt.games.support.DecisionBehavioralTestFixtures.SESSION_ID;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.istStrategy;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

class IstScoringTest {

    private final IstScoringService scoring = new IstScoringService();
    private final IstPosteriorModel posterior = new IstPosteriorModel();
    private final IstLayoutGenerator generator = new IstLayoutGenerator();

    // ── Génération ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("22 grilles déterministes dans l'ordre du protocole, bleues dans la loi a priori")
    void layoutsFollowProtocolAndPrior() {
        List<IstLayoutGenerator.Layout> layouts = generator.generate(SESSION_ID);

        assertThat(generator.generate(SESSION_ID)).isEqualTo(layouts);
        assertThat(layouts).hasSize(IstConfig.TOTAL_TRIAL_COUNT);
        for (IstLayoutGenerator.Layout layout : layouts) {
            IstConfig.TrialSlot slot = IstConfig.slot(layout.trialIndex());
            assertThat(layout.phase()).isEqualTo(slot.phase());
            assertThat(layout.condition()).isEqualTo(slot.condition());
            long blue = layout.boxes().stream().filter(c -> c == IstColor.BLUE).count();
            assertThat(blue).isEqualTo(layout.blueCount())
                .isBetween((long) IstProvisionalRules.BLUE_COUNT_MIN,
                    (long) IstProvisionalRules.BLUE_COUNT_MAX);
            assertThat(layout.majorityColor())
                .isEqualTo(blue >= IstConfig.MAJORITY_THRESHOLD ? IstColor.BLUE : IstColor.ORANGE);
        }
        assertThat(layouts.subList(0, 2)).allMatch(l -> l.phase() == IstPhase.PRACTICE);
        assertThat(layouts.subList(2, 12)).allMatch(l -> l.condition() == IstCondition.FIXED_WIN);
        assertThat(layouts.subList(12, 22)).allMatch(l -> l.condition() == IstCondition.DECREASING_WIN);
    }

    @Test
    @DisplayName("Deux sessions différentes ne reçoivent pas les mêmes grilles")
    void layoutsDifferAcrossSessions() {
        assertThat(generator.generate(UUID.randomUUID())).isNotEqualTo(generator.generate(SESSION_ID));
    }

    // ── P(correct) ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("P(correct) : 0,5 sans information, 1 dès que la majorité est acquise")
    void posteriorBoundaries() {
        assertThat(posterior.pCorrect(0, 0, IstColor.BLUE)).isCloseTo(0.5, within(1e-12));
        assertThat(posterior.pCorrect(13, 0, IstColor.BLUE)).isEqualTo(1.0);
        assertThat(posterior.pCorrect(13, 0, IstColor.ORANGE)).isEqualTo(0.0);
    }

    @Test
    @DisplayName("P(correct) est symétrique et croît avec chaque case concordante")
    void posteriorIsSymmetricAndMonotonic() {
        double previous = 0.5;
        for (int seen = 1; seen <= 12; seen++) {
            double p = posterior.pCorrect(seen, 0, IstColor.BLUE);
            assertThat(p).isGreaterThan(previous);
            assertThat(posterior.pCorrect(0, seen, IstColor.ORANGE)).isCloseTo(p, within(1e-12));
            assertThat(p + posterior.pCorrect(seen, 0, IstColor.ORANGE)).isCloseTo(1.0, within(1e-12));
            previous = p;
        }
    }

    @Test
    @DisplayName("P(correct) égale une dérivation hypergéométrique indépendante, pour toute observation")
    void posteriorMatchesIndependentHypergeometricDerivation() {
        double[] prior = IstProvisionalRules.blueCountPrior();
        for (int a = 0; a <= 19; a++) {
            for (int b = 0; a + b <= 25 && b <= 19; b++) {
                double favourable = 0;
                double total = 0;
                for (int k = 0; k <= 25; k++) {
                    if (prior[k] == 0 || k < a || 25 - k < b) continue;
                    // Forme proportionnelle alternative : C(k,a)·C(25−k,b), sans division.
                    double weight = prior[k] * binom(k, a) * binom(25 - k, b);
                    total += weight;
                    if (k >= 13) favourable += weight;
                }
                if (total == 0) continue;
                assertThat(posterior.pCorrect(a, b, IstColor.BLUE))
                    .as("a=%d b=%d", a, b).isCloseTo(favourable / total, within(1e-9));
            }
        }
    }

    @Test
    @DisplayName("Une observation impossible sous la loi a priori est rejetée")
    void impossibleObservationIsRejected() {
        assertThatThrownBy(() -> posterior.pCorrect(20, 0, IstColor.BLUE))
            .hasMessageContaining("impossible");
    }

    // ── Score et validité ────────────────────────────────────────────────────

    @Test
    @DisplayName("Tout ouvrir partout : exact et sûr, mais aucune adaptation au coût → 80/100")
    void openingEverythingScores80() {
        IstReport report = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 25, 25, 4, false, 300));

        assertThat(report.sessionValid()).isTrue();
        assertThat(report.accuracyPercent()).isEqualTo(100.0);
        assertThat(report.meanPCorrectAtDecision()).isEqualTo(1.0);
        assertThat(report.conditionDiscrimination()).isEqualTo(0.0);
        assertThat(report.provisionalScore()).isEqualTo(80);
    }

    @Test
    @DisplayName("Échantillonner moins quand c'est coûteux rapporte la composante discrimination")
    void adaptingToCostIsRewarded() {
        IstReport adaptive = scoring.report(SESSION_ID,
            istStrategy(SESSION_ID, 25, 15, null, false, 300));

        assertThat(adaptive.conditionDiscrimination()).isEqualTo(10.0);
        assertThat(adaptive.provisionalScore()).isGreaterThan(80);
    }

    @Test
    @DisplayName("Points d'essai : gain fixe, gain décroissant plancher 0, pénalité d'erreur")
    void trialPointsFollowTheConditionRules() {
        assertThat(IstConfig.trialPoints(IstCondition.FIXED_WIN, 25, true)).isEqualTo(100);
        assertThat(IstConfig.trialPoints(IstCondition.DECREASING_WIN, 7, true)).isEqualTo(180);
        assertThat(IstConfig.trialPoints(IstCondition.DECREASING_WIN, 25, true)).isZero();
        assertThat(IstConfig.trialPoints(IstCondition.FIXED_WIN, 3, false)).isEqualTo(-100);
    }

    @Test
    @DisplayName("Décider sans jamais ouvrir de case : run non engagé")
    void nonEngagedRunIsInvalid() {
        IstReport report = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 0, 0, null, false, 300));
        assertThat(report.validityIssues()).contains("NON_ENGAGED");
    }

    @Test
    @DisplayName("Choisir contre une preuve écrasante : réponses aléatoires, run invalide")
    void contrarianRunIsFlaggedAsRandom() {
        IstReport report = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 25, 25, null, true, 300));
        assertThat(report.randomResponseCount()).isEqualTo(20);
        assertThat(report.validityIssues()).contains("RANDOM_RESPONSES");
    }

    @Test
    @DisplayName("Structure : case ouverte deux fois, hors grille, confiance hors échelle, condition fausse")
    void trialStructureIsValidated() {
        List<IstBoxOpening> twice = List.of(new IstBoxOpening(3, 100), new IstBoxOpening(3, 200));
        assertThatThrownBy(() -> new IstTrialMetric(2, IstPhase.TEST, IstCondition.FIXED_WIN,
            twice, IstColor.BLUE, 300, null)).hasMessageContaining("deux fois");
        assertThatThrownBy(() -> new IstTrialMetric(2, IstPhase.TEST, IstCondition.FIXED_WIN,
            List.of(new IstBoxOpening(25, 100)), IstColor.BLUE, 300, null))
            .hasMessageContaining("hors grille");
        assertThatThrownBy(() -> new IstTrialMetric(2, IstPhase.TEST, IstCondition.FIXED_WIN,
            List.of(), IstColor.BLUE, 300, 5)).hasMessageContaining("Confiance");
        assertThatThrownBy(() -> new IstTrialMetric(2, IstPhase.TEST, IstCondition.DECREASING_WIN,
            List.of(), IstColor.BLUE, 300, null)).hasMessageContaining("condition");
    }

    // ── Couche confiance ─────────────────────────────────────────────────────

    @Test
    @DisplayName("« Au hasard » vaut 50 %, « certain » 100 %")
    void confidenceScaleIsAnchoredOnChance() {
        assertThat(IstProvisionalRules.confidenceProbability(1)).isEqualTo(0.5);
        assertThat(IstProvisionalRules.confidenceProbability(4)).isEqualTo(1.0);
    }

    @Test
    @DisplayName("Biais : certain et toujours juste = 0 ; « au hasard » et toujours juste = −0,5 ; aucun jugement = null")
    void calibrationBias() {
        IstReport calibrated = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 25, 25, 4, false, 300));
        IstReport underconfident = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 25, 25, 1, false, 300));
        IstReport skipped = scoring.report(SESSION_ID, istStrategy(SESSION_ID, 25, 25, null, false, 300));

        assertThat(calibrated.calibrationBias()).isEqualTo(0.0);
        assertThat(underconfident.calibrationBias()).isEqualTo(-0.5);
        assertThat(skipped.calibrationBias()).isNull();
        assertThat(skipped.confidenceResponseCount()).isZero();
    }

    private static double binom(int n, int k) {
        double result = 1;
        for (int i = 1; i <= k; i++) result = result * (n - k + i) / i;
        return result;
    }
}
