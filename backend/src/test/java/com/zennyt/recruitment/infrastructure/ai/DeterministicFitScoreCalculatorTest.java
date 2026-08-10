package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.ModuleScore;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.SoftSkillModule;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
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
 *
 * <p><b>Depuis la livraison Games du 2026-08-10</b>, la flexibilité compte <b>3</b> jeux
 * (Move Fast, Je continue, Je coordonne) et la mémoire <b>2</b>. Jouer Move Fast seul ne
 * couvre donc plus qu'un tiers de la flexibilité, là où c'était 100 % quand il était le
 * seul jeu livré. Les valeurs ci-dessous ont chuté pour cette raison : ce n'est pas une
 * régression du calcul, c'est la décote de couverture du CdC §3.3 qui a enfin de quoi
 * s'exercer.
 */
class DeterministicFitScoreCalculatorTest {

    /** Technique/Senior — hard 65, soft 35, modules 30/20/30/15/5 (matrice v4.1). */
    private static final JobRoleProfile TECHNIQUE_SENIOR = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 35, 65, 65, 30, 20, 30, 15, 5, false, Instant.now());

    /** Relationnel/Senior — hard 20, soft 80, modules 10/10/20/15/45 (matrice v4.1). */
    private static final JobRoleProfile RELATIONNEL_SENIOR = new JobRoleProfile(
        JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR, 80, 20, 20, 10, 10, 20, 15, 45, false, Instant.now());

    private final DeterministicFitScoreCalculator calculator = new DeterministicFitScoreCalculator();

    private FitScoreResult score(Map<String, ModuleScore> modules, JobRoleProfile profile, Integer hard) {
        return calculator.calculate(new FitScoreInputs(modules, profile, hard));
    }

    @Test
    @DisplayName("Un seul jeu joué : le module est couvert, la couverture globale reste basse")
    void unSeulJeuJoueDonneUneCouvertureGlobaleBasse() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", ModuleScore.fullyCovered(90)), TECHNIQUE_SENIOR, null);

        // Un jeu sur les 3 de la flexibilité : le module n'est couvert qu'à 33 %.
        assertThat(result.softSkillScore()).isEqualTo(13);   // 90 × 0,33 × 30 / 70
        assertThat(result.coverageRatio()).isEqualTo(14);    // 33 × 30 / 70
    }

    @Test
    @DisplayName("CdC §3.3 — une couverture partielle réduit le score proportionnellement")
    void couverturePartielleReduitLeScore() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", new ModuleScore(90, 40)), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(5);   // 90 × (40/3) % × 30 / 70
        assertThat(result.coverageRatio()).isEqualTo(6);    // (40/3) × 30 / 70
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

        // Flexibilité : 100 sur 3 jeux = 33 %. Mémoire : 50 sur 2 jeux = 25 %.
        assertThat(result.softSkillScore()).isEqualTo(17);   // (80×0,33×30 + 80×0,25×20) / 70
        assertThat(result.coverageRatio()).isEqualTo(21);    // (33×30 + 25×20) / 70
    }

    @Test
    @DisplayName("Le poids hard ne s'applique qu'une fois le QCM passé")
    void poidsHardSeulementApresLeQcm() {
        Map<String, ModuleScore> joue = Map.of("MOVE_FAST", ModuleScore.fullyCovered(80));

        // soft = 80 × 0,33 × 30 / 70 = 11,4 ; fit = 11,4 × 35 % + 60 × 65 % = 43,0
        assertThat(score(joue, TECHNIQUE_SENIOR, 60).score()).isEqualTo(43);

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

        // Technique, dénominateur 70 : (50×0,33×30 + 55×0,50×20 + 70×1,00×15) / 70 = 30
        assertThat(score(candidat, TECHNIQUE_SENIOR, null).softSkillScore()).isEqualTo(30);
        // Relationnel, dénominateur 80 : (50×0,33×10 + 55×0,50×10 + 70×1,00×15) / 80 = 19
        assertThat(score(candidat, RELATIONNEL_SENIOR, null).softSkillScore()).isEqualTo(19);
    }

    @Test
    @DisplayName("La régulation émotionnelle livrée par Games est bien pondérée")
    void regulationEmotionnellePonderee() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "EMOTIONAL_REGULATION", ModuleScore.fullyCovered(20)),
            TECHNIQUE_SENIOR, null);

        // (80×0,33×30 + 20×1,00×5) / 70 = 12,9. Régulation ignorée, ce serait 11,4 :
        // l'écart prouve que le module compte bien.
        assertThat(result.softSkillScore()).isEqualTo(13);
    }

    @Test
    @DisplayName("Une clé de module inconnue est ignorée, jamais promue en score")
    void cleDeModuleInconnueIgnoree() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(10)),
            TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(11);   // identique à MOVE_FAST seul
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

        // « Parfait » veut dire : TOUS les jeux livrés, pas seulement un par module.
        // Depuis le 2026-08-10 cela fait 7 jeux et non 4.
        Map<String, ModuleScore> parfait = new LinkedHashMap<>();
        parfait.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        parfait.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(100));
        parfait.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(100));
        parfait.put("MEMORY_QUEST", ModuleScore.fullyCovered(100));
        parfait.put("VISUOSPATIAL_MEMORY", ModuleScore.fullyCovered(100));
        parfait.put("PLANIFIK", ModuleScore.fullyCovered(100));
        parfait.put("EMOTIONAL_REGULATION", ModuleScore.fullyCovered(100));

        FitScoreResult result = score(parfait, TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(100);
        assertThat(result.coverageRatio()).isEqualTo(100);
    }

    /**
     * Un module peut être alimenté par PLUSIEURS jeux (Flexibilité cognitive =
     * Move Fast + Je continue + Je coordonne, cf. GAMES_MODULE.md). Sans regroupement
     * préalable, son poids serait compté une fois par jeu — 30+30+30 = 90 points sur un
     * dénominateur de 70 — et un candidat qui ne joue QUE de la flexibilité dépasserait
     * 100 alors qu'il n'a rien montré des trois autres modules.
     */
    @Test
    @DisplayName("Plusieurs jeux d'un même module : le poids n'est compté qu'une fois")
    void plusieursJeuxUnSeulPoids() {
        Map<String, ModuleScore> tousLesJeuxDeFlex = new LinkedHashMap<>();
        tousLesJeuxDeFlex.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        tousLesJeuxDeFlex.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(100));
        tousLesJeuxDeFlex.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(100));

        FitScoreResult result = score(tousLesJeuxDeFlex, TECHNIQUE_SENIOR, null);

        // La flexibilité pèse 30 sur 70, et rien d'autre n'est mesuré : 43, pas 129.
        assertThat(result.softSkillScore()).isEqualTo(43);
        assertThat(result.coverageRatio()).isEqualTo(43);

        // Corollaire : jouer les 3 jeux vaut mieux que d'en jouer un seul.
        int unSeul = score(Map.of("MOVE_FAST", ModuleScore.fullyCovered(100)),
            TECHNIQUE_SENIOR, null).softSkillScore();
        assertThat(result.softSkillScore()).isGreaterThan(unSeul);
    }
}
