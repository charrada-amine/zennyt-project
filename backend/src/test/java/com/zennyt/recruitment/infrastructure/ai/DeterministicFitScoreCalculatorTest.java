package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.ModuleScore;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.SoftSkillModule;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.assertj.core.data.Offset;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Comportement du calculateur, module par module.
 *
 * <p>Repère utile pour lire les valeurs attendues : sur un profil <b>Technique</b>,
 * les poids sont 30/20/30/15/5 (flexibilité, mémoire, décision, planification,
 * régulation). La <b>Prise de décision sort du dénominateur</b> tant que « Je Décide »
 * n'a pas ses 30 scénarios — le dénominateur vaut donc 30+20+15+5 = <b>70</b>, et non
 * 100. Un candidat qui n'a joué qu'un seul jeu obtient logiquement un score bas
 * <i>et</i> une couverture basse : c'est le signal attendu, pas un bug.
 */
class DeterministicFitScoreCalculatorTest {

    /** Technique/Senior — hard 65, soft 35, modules 30/20/30/15/5 (matrice v4.1). */
    private static final JobRoleProfile TECHNIQUE_SENIOR = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 35, 65, 65, 30, 20, 30, 15, 5,
        TypeEvaluationHard.QCM, false, Instant.now());

    /** Relationnel/Senior — hard 20, soft 80, modules 10/10/20/15/45 (matrice v4.1). */
    private static final JobRoleProfile RELATIONNEL_SENIOR = new JobRoleProfile(
        JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR, 80, 20, 20, 10, 10, 20, 15, 45,
        TypeEvaluationHard.QCM, false, Instant.now());

    private final DeterministicFitScoreCalculator calculator = new DeterministicFitScoreCalculator();

    private FitScoreResult score(Map<String, ModuleScore> modules, JobRoleProfile profile, Integer hard) {
        return calculator.calculate(new FitScoreInputs(modules, profile, hard));
    }

    @Test
    @DisplayName("Un seul jeu joué : le module est couvert, la couverture globale reste basse")
    void unSeulJeuJoueDonneUneCouvertureGlobaleBasse() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", ModuleScore.fullyCovered(90)), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(39);   // 90 × 30 / 70
        // La flexibilité (30) est couverte, les 3 autres modules mesurables ne le sont
        // pas : 100 × 30 / 70 = 43 %. En dessous des deux seuils du mécanisme 2.
        assertThat(result.coverageRatio()).isEqualTo(43);
    }

    @Test
    @DisplayName("CdC §3.3 — une couverture partielle réduit le score proportionnellement")
    void couverturePartielleReduitLeScore() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", new ModuleScore(90, 40)), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(15);   // 90 × 0,40 × 30 / 70
        assertThat(result.coverageRatio()).isEqualTo(17);    // 40 × 30 / 70
    }

    /**
     * F13/F15 — deux modules aux couvertures différentes. Le CdC applique la décote
     * module par module AVANT l'agrégation ; l'ancienne implémentation, qui ne
     * connaissait qu'un ratio global unique, ne pouvait pas produire ce résultat.
     */
    @Test
    @DisplayName("Deux couvertures différentes sont appliquées avant l'agrégation")
    void couverturesDifferentesAppliqueesAvantAgregation() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", new ModuleScore(80, 100),      // poids 30, pleinement couvert
            "MEMORY_QUEST", new ModuleScore(80, 50)),   // poids 20, à moitié couvert
            TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(46);   // (80×1,00×30 + 80×0,50×20) / 70
        assertThat(result.coverageRatio()).isEqualTo(57);    // (100×30 + 50×20) / 70
    }

    @Test
    @DisplayName("Le poids hard ne s'applique qu'une fois le QCM passé")
    void poidsHardSeulementApresLeQcm() {
        Map<String, ModuleScore> joue = Map.of("MOVE_FAST", ModuleScore.fullyCovered(80));

        // soft = 80 × 30 / 70 = 34,3 ; fit = 34,3 × 35 % + 60 × 65 % = 51,0
        assertThat(score(joue, TECHNIQUE_SENIOR, 60).score()).isEqualTo(51);

        FitScoreResult sansQcm = score(joue, TECHNIQUE_SENIOR, null);
        assertThat(sansQcm.score()).isEqualTo(sansQcm.softSkillScore());
    }

    @Test
    @DisplayName("Sans pondération résolue, rien n'est calculé ni écrit")
    void offreSansMetierApprouve() {
        assertThat(score(Map.of("MOVE_FAST", ModuleScore.fullyCovered(90)), null, null)).isNull();
    }

    /**
     * Garde-fou du correctif du 2026-07-30 : avant, tous les modules du candidat
     * étaient aplatis en une moyenne unique avant que la pondération métier ne puisse
     * s'exercer, rendant le Score_Soft identique quel que soit le métier de l'offre.
     * Le CdC §3.2 prévoit l'inverse.
     */
    @Test
    @DisplayName("Le même candidat n'obtient pas le même score sur deux métiers différents")
    void memeCandidatScoresDifferentsSelonLeMetier() {
        Map<String, ModuleScore> candidat = new LinkedHashMap<>();
        candidat.put("MOVE_FAST", ModuleScore.fullyCovered(50));       // flexibilité
        candidat.put("MEMORY_QUEST", ModuleScore.fullyCovered(55));    // mémoire
        candidat.put("PLANIFIK", ModuleScore.fullyCovered(70));        // planification

        // Technique, dénominateur 70 : (50×30 + 55×20 + 70×15) / 70 = 52
        assertThat(score(candidat, TECHNIQUE_SENIOR, null).softSkillScore()).isEqualTo(52);
        // Relationnel, dénominateur 80 : (50×10 + 55×10 + 70×15) / 80 = 26
        assertThat(score(candidat, RELATIONNEL_SENIOR, null).softSkillScore()).isEqualTo(26);
    }

    @Test
    @DisplayName("La régulation émotionnelle livrée par Games est bien pondérée")
    void regulationEmotionnellePonderee() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "EMOTIONAL_REGULATION", ModuleScore.fullyCovered(20)),
            TECHNIQUE_SENIOR, null);

        // (80×30 + 20×5) / 70 = 35,7. Ignorée, ce serait 34 : l'écart prouve que le
        // module compte bien.
        assertThat(result.softSkillScore()).isEqualTo(36);
    }

    @Test
    @DisplayName("Une clé de module inconnue est ignorée, jamais promue en score")
    void cleDeModuleInconnueIgnoree() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(10)),
            TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(34);   // identique à MOVE_FAST seul
        // Seule, une clé inconnue ne produit aucun score du tout.
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(90)),
            TECHNIQUE_SENIOR, null)).isNull();
    }

    /**
     * Décision D-D ajustée le 2026-08-05 — « Je Décide » a son moteur et ses écrans,
     * mais son catalogue de 30 scénarios est vide. Le module sort donc du calcul :
     * sans ça, un candidat parfait plafonnerait à 70/100 sur un profil Technique,
     * soit exactement le seuil « bon profil ».
     */
    @Test
    @DisplayName("Un module dont aucun jeu n'existe ne plafonne pas les candidats")
    void moduleSansJeuDisponibleNePlafonnePas() {
        assertThat(SoftSkillModule.DECISION_MAKING.unmeasurable()).isTrue();

        Map<String, ModuleScore> parfait = new LinkedHashMap<>();
        parfait.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        parfait.put("MEMORY_QUEST", ModuleScore.fullyCovered(100));
        parfait.put("PLANIFIK", ModuleScore.fullyCovered(100));
        parfait.put("EMOTIONAL_REGULATION", ModuleScore.fullyCovered(100));

        FitScoreResult result = score(parfait, TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(100);
        assertThat(result.coverageRatio()).isEqualTo(100);
    }

    /**
     * Un module peut être alimenté par PLUSIEURS jeux (Flexibilité cognitive =
     * Move Fast + Je continue + Je coordonne, cf. GAMES_MODULE.md). Sans regroupement
     * préalable, son poids serait compté une fois par jeu — 30+30+30 = 90 points sur
     * 100 au lieu de 30 — et le module écraserait tous les autres.
     */
    @Test
    @DisplayName("Plusieurs jeux d'un même module : le poids n'est compté qu'une fois")
    void plusieursJeuxUnSeulPoids() {
        Map<String, ModuleScore> unJeuDeFlex = new LinkedHashMap<>();
        unJeuDeFlex.put("MOVE_FAST", ModuleScore.fullyCovered(80));
        unJeuDeFlex.put("MEMORY_QUEST", ModuleScore.fullyCovered(75));

        Map<String, ModuleScore> troisJeuxDeFlex = new LinkedHashMap<>(unJeuDeFlex);
        troisJeuxDeFlex.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(90));
        troisJeuxDeFlex.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(60));

        int avecUnJeu = score(unJeuDeFlex, TECHNIQUE_SENIOR, null).softSkillScore();
        int avecTroisJeux = score(troisJeuxDeFlex, TECHNIQUE_SENIOR, null).softSkillScore();

        // La flexibilité passe de 80 à la moyenne des 3 jeux (76,7) : quelques points
        // d'écart. Si le poids était compté trois fois, l'écart serait massif.
        assertThat(avecTroisJeux).isCloseTo(avecUnJeu, Offset.offset(3));
    }
}
