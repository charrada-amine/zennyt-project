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
 * régulation). Depuis l'activation de « Je Décide » (2026-08-12, catalogue de 120
 * items livré), la <b>Prise de décision est mesurable et compte au dénominateur</b> :
 * il vaut donc 30+20+30+15+5 = <b>100</b>.
 *
 * <p>En revanche, la flexibilité et la mémoire ne comptent aujourd'hui qu'<b>un seul
 * jeu disponible</b> chacune (Je continue / Je coordonne / Je place livrés par Games
 * mais pas encore fusionnés côté recrutement, cf. {@link SoftSkillModule}). Jouer
 * Move Fast couvre donc la flexibilité à 100 % (1 jeu sur 1), pas à un tiers. Un
 * candidat qui n'a joué qu'un seul module obtient logiquement un score bas <i>et</i>
 * une couverture basse : c'est le signal attendu, pas un bug.
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

        // Flexibilité = 1 jeu disponible → Move Fast la couvre à 100 %. Les 4 autres
        // modules mesurables ne sont pas joués : seul le poids 30 contribue.
        assertThat(result.softSkillScore()).isEqualTo(27);   // 90 × 30 / 100
        assertThat(result.coverageRatio()).isEqualTo(30);    // 100 × 30 / 100
    }

    @Test
    @DisplayName("CdC §3.3 — une couverture partielle réduit le score proportionnellement")
    void couverturePartielleReduitLeScore() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", new ModuleScore(90, 40)), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(11);   // 90 × 0,40 × 30 / 100
        assertThat(result.coverageRatio()).isEqualTo(12);    // 40 × 30 / 100
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

        assertThat(result.softSkillScore()).isEqualTo(32);   // (80×1,00×30 + 80×0,50×20) / 100
        assertThat(result.coverageRatio()).isEqualTo(40);    // (100×30 + 50×20) / 100
    }

    @Test
    @DisplayName("Le poids hard ne s'applique qu'une fois le QCM passé")
    void poidsHardSeulementApresLeQcm() {
        Map<String, ModuleScore> joue = Map.of("MOVE_FAST", ModuleScore.fullyCovered(80));

        // soft = 80 × 30 / 100 = 24 ; fit = 24 × 35 % + 60 × 65 % = 47,4 -> 47
        assertThat(score(joue, TECHNIQUE_SENIOR, 60).score()).isEqualTo(47);

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

        // Technique, dénominateur 100 : (50×30 + 55×20 + 70×15) / 100 = 37
        assertThat(score(candidat, TECHNIQUE_SENIOR, null).softSkillScore()).isEqualTo(37);
        // Relationnel, dénominateur 100 : (50×10 + 55×10 + 70×15) / 100 = 21
        assertThat(score(candidat, RELATIONNEL_SENIOR, null).softSkillScore()).isEqualTo(21);
    }

    @Test
    @DisplayName("La régulation émotionnelle livrée par Games est bien pondérée")
    void regulationEmotionnellePonderee() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "EMOTIONAL_REGULATION", ModuleScore.fullyCovered(20)),
            TECHNIQUE_SENIOR, null);

        // (80×30 + 20×5) / 100 = 25. Régulation ignorée, ce serait 24 : l'écart prouve
        // que le module compte bien.
        assertThat(result.softSkillScore()).isEqualTo(25);
    }

    @Test
    @DisplayName("Une clé de module inconnue est ignorée, jamais promue en score")
    void cleDeModuleInconnueIgnoree() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(10)),
            TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(24);   // identique à MOVE_FAST seul (80×30/100)
        // Seule, une clé inconnue ne produit aucun score du tout.
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(90)),
            TECHNIQUE_SENIOR, null)).isNull();
    }

    /**
     * Décision D-D, révisée le 2026-08-12 — « Je Décide » est désormais livré
     * (catalogue de 120 items, {@code DECISION_CORE.isPlayable() == true}). Le module
     * est mesurable et pèse pour de bon : sur un profil Technique (poids décision 30 %),
     * un candidat qui ne l'a pas joué plafonne à 70/100 ; ne l'atteint 100 que celui
     * qui a joué tous les jeux, décision comprise. C'est l'exact inverse de l'ancienne
     * règle qui sortait la décision du calcul faute de catalogue.
     */
    @Test
    @DisplayName("La décision est mesurable : ne pas la jouer plafonne le score")
    void laDecisionCompteDesormaisDansLeScore() {
        assertThat(SoftSkillModule.DECISION_MAKING.unmeasurable()).isFalse();

        // « Parfait » = un jeu par module mesurable, décision comprise, tous à 100.
        Map<String, ModuleScore> parfait = new LinkedHashMap<>();
        parfait.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        parfait.put("MEMORY_QUEST", ModuleScore.fullyCovered(100));
        parfait.put("DECISION", ModuleScore.fullyCovered(100));
        parfait.put("PLANIFIK", ModuleScore.fullyCovered(100));
        parfait.put("EMOTIONAL_REGULATION", ModuleScore.fullyCovered(100));

        FitScoreResult result = score(parfait, TECHNIQUE_SENIOR, null);
        assertThat(result.softSkillScore()).isEqualTo(100);
        assertThat(result.coverageRatio()).isEqualTo(100);

        // Le même candidat SANS avoir joué la décision : le poids 30 % reste au
        // dénominateur mais ne contribue rien -> plafond à 70.
        Map<String, ModuleScore> sansDecision = new LinkedHashMap<>(parfait);
        sansDecision.remove("DECISION");
        assertThat(score(sansDecision, TECHNIQUE_SENIOR, null).softSkillScore()).isEqualTo(70);
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

        // La flexibilité passe de 80 à la moyenne des jeux rattachés : quelques points
        // d'écart. Si le poids était compté trois fois, l'écart serait massif.
        assertThat(avecTroisJeux).isCloseTo(avecUnJeu, Offset.offset(3));
    }
}
