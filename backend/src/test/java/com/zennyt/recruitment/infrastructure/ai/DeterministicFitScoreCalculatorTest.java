package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class DeterministicFitScoreCalculatorTest {

    /** Technique/Senior — hard 65, soft 35 (matrice v4.1). */
    private static final JobRoleProfile TECHNIQUE_SENIOR = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.MID, 35, 65, 65, 30, 20, 30, 15, 5,
        TypeEvaluationHard.QCM, false);

    @Test
    void fullCoverageLeavesSoftScoreUnchanged() {
        // CdC §3.3 : score brut 90, couverture 100% -> score ajusté 90 (inchangé).
        var calculator = new DeterministicFitScoreCalculator(inputs -> new FitScoreResult(0, 0, 0));
        var inputs = new FitScoreInputs(Map.of("games", 90.0), null, "desc", null,
            TECHNIQUE_SENIOR, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        // Pas de QCM (hardSkillScore null) -> poidsHard=0, le score = le soft ajusté seul.
        assertThat(result.softSkillScore()).isEqualTo(90);
        assertThat(result.score()).isEqualTo(90);
    }

    @Test
    void partialCoverageReducesSoftScoreProportionally() {
        // CdC §3.3 : score brut 90, couverture 40% -> score ajusté 36.
        var calculator = new DeterministicFitScoreCalculator(inputs -> new FitScoreResult(0, 0, 0));
        var inputs = new FitScoreInputs(Map.of("games", 90.0), null, "desc", null,
            TECHNIQUE_SENIOR, null, 40);

        FitScoreResult result = calculator.calculate(inputs);

        assertThat(result.softSkillScore()).isEqualTo(36);
        assertThat(result.score()).isEqualTo(36);
    }

    @Test
    void hardWeightAppliesOnlyWhenAttemptCompleted() {
        var calculator = new DeterministicFitScoreCalculator(inputs -> new FitScoreResult(0, 0, 0));
        var inputs = new FitScoreInputs(Map.of("games", 80.0), null, "desc", null,
            TECHNIQUE_SENIOR, 60, 100);

        FitScoreResult result = calculator.calculate(inputs);

        // 80*35 + 60*65 = 6700 -> /100 = 67.
        assertThat(result.score()).isEqualTo(67);
    }

    @Test
    void delegatesToFallbackWhenOfferHasNoResolvedRoleProfile() {
        FitScoreCalculatorPort fallback = inputs -> new FitScoreResult(42, 42, 42);
        var calculator = new DeterministicFitScoreCalculator(fallback);
        var inputs = new FitScoreInputs(Map.of("games", 90.0), null, "desc", null,
            null, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        assertThat(result.score()).isEqualTo(42);
    }
}
