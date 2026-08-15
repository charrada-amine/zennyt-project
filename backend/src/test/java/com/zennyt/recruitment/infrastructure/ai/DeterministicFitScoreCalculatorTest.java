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
 * régulation). Depuis la livraison du catalogue « Je Décide » (2026-08-12, 120 items),
 * <b>les cinq modules sont mesurables</b> : le dénominateur vaut donc <b>100</b>. Il a
 * valu 70 tant que la prise de décision restait inatteignable — les valeurs de ce
 * fichier ont baissé d'autant, sans qu'aucune pondération ne bouge.
 *
 * <p>Un candidat qui n'a joué qu'un seul jeu obtient logiquement un score bas <i>et</i>
 * une couverture basse : c'est le signal attendu, pas un bug. Il l'obtient même deux
 * fois, puisque la flexibilité compte 3 jeux depuis le 10 août et que la prise de
 * décision pèse maintenant au dénominateur.
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
        assertThat(result.softSkillScore()).isEqualTo(9);    // 90 × 0,33 × 30 / 100
        assertThat(result.coverageRatio()).isEqualTo(10);    // 33 × 30 / 100
    }

    @Test
    @DisplayName("CdC §3.3 — une couverture partielle réduit le score proportionnellement")
    void couverturePartielleReduitLeScore() {
        FitScoreResult result = score(
            Map.of("MOVE_FAST", new ModuleScore(90, 40)), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(4);   // 90 × (40/3) % × 30 / 100
        assertThat(result.coverageRatio()).isEqualTo(4);    // (40/3) × 30 / 100
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
        assertThat(result.softSkillScore()).isEqualTo(12);   // (80×0,33×30 + 80×0,25×20) / 100
        assertThat(result.coverageRatio()).isEqualTo(15);    // (33×30 + 25×20) / 100
    }

    @Test
    @DisplayName("Le poids hard ne s'applique qu'une fois le QCM passé")
    void poidsHardSeulementApresLeQcm() {
        Map<String, ModuleScore> joue = Map.of("MOVE_FAST", ModuleScore.fullyCovered(80));

        // soft = 80 × 0,33 × 30 / 100 = 8,0 ; fit = 8,0 × 35 % + 60 × 65 % = 41,8
        assertThat(score(joue, TECHNIQUE_SENIOR, 60).score()).isEqualTo(42);

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

        // Technique, dénominateur 100 : (50×0,33×30 + 55×0,50×20 + 70×1,00×15) / 100 = 21
        assertThat(score(candidat, TECHNIQUE_SENIOR, null).softSkillScore()).isEqualTo(21);
        // Relationnel, dénominateur 100 : (50×0,33×10 + 55×0,50×10 + 70×1,00×15) / 100 = 15
        assertThat(score(candidat, RELATIONNEL_SENIOR, null).softSkillScore()).isEqualTo(15);
    }

    @Test
    @DisplayName("La régulation émotionnelle livrée par Games est bien pondérée")
    void regulationEmotionnellePonderee() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "EMOTIONAL_REGULATION", ModuleScore.fullyCovered(20)),
            TECHNIQUE_SENIOR, null);

        // (80×0,33×30 + 20×1,00×5) / 100 = 9,0. Régulation ignorée, ce serait 8,0 :
        // l'écart prouve que le module compte bien.
        assertThat(result.softSkillScore()).isEqualTo(9);
    }

    @Test
    @DisplayName("Une clé de module inconnue est ignorée, jamais promue en score")
    void cleDeModuleInconnueIgnoree() {
        FitScoreResult result = score(Map.of(
            "MOVE_FAST", ModuleScore.fullyCovered(80),
            "JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(10)),
            TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(8);    // identique à MOVE_FAST seul
        // Seule, une clé inconnue ne produit aucun score du tout.
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(90)),
            TECHNIQUE_SENIOR, null)).isNull();
    }

    /**
     * Depuis la livraison du catalogue « Je Décide » (2026-08-12), <b>plus aucun module
     * n'est hors du calcul</b> : les cinq pèsent, le dénominateur vaut 100. Le mécanisme
     * d'exclusion reste en place et testé — il servira si Games retire un jour un jeu —
     * mais il ne s'applique aujourd'hui à personne.
     *
     * <p>« Parfait » veut donc dire : les <b>8</b> jeux livrés, « Je Décide » compris.
     */
    @Test
    @DisplayName("Un candidat qui a tout joué atteint bien 100, sans plafond")
    void candidatCompletAtteintCent() {
        assertThat(SoftSkillModule.DECISION_MAKING.unmeasurable()).isFalse();

        FitScoreResult result = score(candidatComplet(), TECHNIQUE_SENIOR, null);

        assertThat(result.softSkillScore()).isEqualTo(100);
        assertThat(result.coverageRatio()).isEqualTo(100);
    }

    /**
     * Le changement de comportement le plus visible de la livraison du 2026-08-12, et
     * celui qu'un candidat remarquera : « Je Décide » pèse 30 sur un profil Technique.
     * Ne pas y jouer coûtait <b>zéro</b> la veille — le module était ignoré — et coûte
     * désormais exactement son poids.
     */
    @Test
    @DisplayName("Ne pas jouer « Je Décide » coûte exactement le poids du module")
    void ignorerLaPriseDeDecisionCouteSonPoids() {
        Map<String, ModuleScore> sansDecision = new LinkedHashMap<>(candidatComplet());
        sansDecision.remove("DECISION");

        FitScoreResult result = score(sansDecision, TECHNIQUE_SENIOR, null);

        // 100 - 30 (le poids de la prise de décision sur ce profil).
        assertThat(result.softSkillScore()).isEqualTo(70);
        assertThat(result.coverageRatio()).isEqualTo(70);
    }

    /** Les 8 jeux livrés, tous parfaitement réussis et pleinement couverts. */
    private static Map<String, ModuleScore> candidatComplet() {
        Map<String, ModuleScore> parfait = new LinkedHashMap<>();
        parfait.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        parfait.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(100));
        parfait.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(100));
        parfait.put("MEMORY_QUEST", ModuleScore.fullyCovered(100));
        parfait.put("VISUOSPATIAL_MEMORY", ModuleScore.fullyCovered(100));
        parfait.put("DECISION", ModuleScore.fullyCovered(100));
        parfait.put("PLANIFIK", ModuleScore.fullyCovered(100));
        parfait.put("EMOTIONAL_REGULATION", ModuleScore.fullyCovered(100));
        return parfait;
    }

    /**
     * Un module peut être alimenté par PLUSIEURS jeux (Flexibilité cognitive =
     * Move Fast + Je continue + Je coordonne, cf. GAMES_MODULE.md). Sans regroupement
     * préalable, son poids serait compté une fois par jeu — 30+30+30 = 90 points sur un
     * dénominateur de 100 — et un candidat qui ne joue QUE de la flexibilité obtiendrait
     * 90 alors qu'il n'a rien montré des quatre autres modules.
     */
    @Test
    @DisplayName("Plusieurs jeux d'un même module : le poids n'est compté qu'une fois")
    void plusieursJeuxUnSeulPoids() {
        Map<String, ModuleScore> tousLesJeuxDeFlex = new LinkedHashMap<>();
        tousLesJeuxDeFlex.put("MOVE_FAST", ModuleScore.fullyCovered(100));
        tousLesJeuxDeFlex.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(100));
        tousLesJeuxDeFlex.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(100));

        FitScoreResult result = score(tousLesJeuxDeFlex, TECHNIQUE_SENIOR, null);

        // La flexibilité pèse 30 sur 100, et rien d'autre n'est mesuré : 30, pas 90.
        assertThat(result.softSkillScore()).isEqualTo(30);
        assertThat(result.coverageRatio()).isEqualTo(30);

        // Corollaire : jouer les 3 jeux vaut mieux que d'en jouer un seul.
        int unSeul = score(Map.of("MOVE_FAST", ModuleScore.fullyCovered(100)),
            TECHNIQUE_SENIOR, null).softSkillScore();
        assertThat(result.softSkillScore()).isGreaterThan(unSeul);
    }
}
