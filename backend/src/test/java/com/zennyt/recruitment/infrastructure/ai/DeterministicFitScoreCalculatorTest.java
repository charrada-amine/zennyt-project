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

    /** Technique/Mid — hard 65, soft 35, modules 30/20/30/15/5 (matrice v4.1). */
    private static final JobRoleProfile TECHNIQUE_SENIOR = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 35, 65, 65, 30, 20, 30, 15, 5,
        TypeEvaluationHard.QCM, false, java.time.Instant.now());

    /** Relationnel/Mid — hard 25, soft 75, modules 10/10/20/15/45 (matrice v4.1). */
    private static final JobRoleProfile RELATIONNEL_MID = new JobRoleProfile(
        JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR, 75, 25, 25, 10, 10, 20, 15, 45,
        TypeEvaluationHard.QCM, false, java.time.Instant.now());

    @Test
    void fullCoverageLeavesSoftScoreUnchanged() {
        // CdC §3.3 : score brut 90, couverture 100% -> score ajusté 90 (inchangé).
        // Un seul module : la pondération est mathématiquement un no-op (90*w/w = 90),
        // donc ce test isole bien le mécanisme de couverture, pas la pondération.
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MOVE_FAST", 90.0),
            TECHNIQUE_SENIOR, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        // Pas de QCM (hardSkillScore null) -> poidsHard=0, le score = le soft ajusté seul.
        assertThat(result.softSkillScore()).isEqualTo(90);
        assertThat(result.score()).isEqualTo(90);
    }

    @Test
    void partialCoverageReducesSoftScoreProportionally() {
        // CdC §3.3 : score brut 90, couverture 40% -> score ajusté 36.
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MOVE_FAST", 90.0),
            TECHNIQUE_SENIOR, null, 40);

        FitScoreResult result = calculator.calculate(inputs);

        assertThat(result.softSkillScore()).isEqualTo(36);
        assertThat(result.score()).isEqualTo(36);
    }

    @Test
    void hardWeightAppliesOnlyWhenAttemptCompleted() {
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MOVE_FAST", 80.0),
            TECHNIQUE_SENIOR, 60, 100);

        FitScoreResult result = calculator.calculate(inputs);

        // 80*35 + 60*65 = 6700 -> /100 = 67.
        assertThat(result.score()).isEqualTo(67);
    }

    @Test
    void computesNothingWhenOfferHasNoResolvedRoleProfile() {
        // Remplace l'ancien test de repli sur un moteur IA externe : ce repli est
        // supprimé. Sans pondération résolue (offre sans métier, ou métier pas encore
        // approuvé), il n'y a pas de score à inventer — rien n'est calculé ni écrit.
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MOVE_FAST", 90.0),
            null, null, 100);

        assertThat(calculator.calculate(inputs)).isNull();
    }

    /**
     * Garde-fou central du correctif demandé par le superviseur (2026-07-30) : avant ce
     * correctif, RecomputeFitScoresUseCase aplatissait tous les modules du candidat en
     * une moyenne unique avant que la pondération métier ne puisse s'exercer, rendant le
     * Score_Soft strictement identique quel que soit le métier de l'offre. Le CdC §3.2
     * prévoit l'inverse : un score par module pondéré par métier, dès le Score_Soft,
     * indépendamment de la présence d'un QCM (D2 ne met à 0 que le poids du hard).
     *
     * <p>Même candidat, mêmes 3 scores de modules mesurables, sans aucun TestResult
     * (poidsHard=0 dans les deux cas) — seul le profil métier de l'offre change.
     */
    @Test
    void memeCandidatObtientDesScoreSoftDifferentsSurDeuxMetiersSansAucunTest() {
        var calculator = new DeterministicFitScoreCalculator();
        Map<String, Double> modulesCandidat = Map.of(
            "MOVE_FAST", 50.0,      // Flexibilité cognitive
            "MEMORY_QUEST", 55.0,   // Mémoire de travail
            "PLANIFIK", 70.0);      // Planification exécutive

        FitScoreResult surTechnique = calculator.calculate(new FitScoreInputs(
            modulesCandidat, TECHNIQUE_SENIOR, null, 100));
        FitScoreResult surRelationnel = calculator.calculate(new FitScoreInputs(
            modulesCandidat, RELATIONNEL_MID, null, 100));

        // Technique (30/20/15 sur ces 3 modules, renormalisé) : (50*30+55*20+70*15)/65 = 56.
        assertThat(surTechnique.softSkillScore()).isEqualTo(56);
        // Relationnel (10/10/15 sur ces 3 modules, renormalisé) : (50*10+55*10+70*15)/35 = 60.
        assertThat(surRelationnel.softSkillScore()).isEqualTo(60);
        assertThat(surTechnique.softSkillScore()).isNotEqualTo(surRelationnel.softSkillScore());
    }

    /**
     * Games a livré « Je gère » (régulation émotionnelle) après ce correctif — vérifie
     * que le module est bien reconnu et pondéré, pas silencieusement ignoré comme le
     * serait une clé inconnue (voir {@code ignoreUneCleDeModuleNonReconnueSansEchouer}).
     */
    @Test
    void reconnaitLeModuleRegulationEmotionnelleDesormaisLivreParGames() {
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(
            Map.of("MOVE_FAST", 80.0, "EMOTIONAL_REGULATION", 20.0),
            TECHNIQUE_SENIOR, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        // Technique : cognitif=30, régulation=5 -> (80*30+20*5)/35 = 71.
        // Ignoré, ce serait 80*30/30 = 80 : la différence prouve que le module compte.
        assertThat(result.softSkillScore()).isEqualTo(71);
    }

    @Test
    void renormaliseSurLesSeulsModulesJoues() {
        // Le candidat n'a joué qu'un seul mini-jeu sur les 3 mesurables aujourd'hui :
        // la pondération doit se renormaliser sur ce seul module, pas retomber à 0.
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MEMORY_QUEST", 80.0),
            TECHNIQUE_SENIOR, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        assertThat(result.softSkillScore()).isEqualTo(80);
    }

    @Test
    void ignoreUneCleDeModuleNonReconnueSansEchouer() {
        // Un module Games qui ne correspond à aucun module CdC (ex. futur module non
        // encore câblé dans SoftSkillModule) est ignoré, pas fatal au calcul.
        var calculator = new DeterministicFitScoreCalculator();
        var inputs = new FitScoreInputs(Map.of("MOVE_FAST", 80.0, "MODULE_INCONNU", 10.0),
            TECHNIQUE_SENIOR, null, 100);

        FitScoreResult result = calculator.calculate(inputs);

        assertThat(result.softSkillScore()).isEqualTo(80);
    }
}
