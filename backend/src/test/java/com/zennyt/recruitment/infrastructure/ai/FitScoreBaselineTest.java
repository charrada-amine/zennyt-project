package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.ModuleScore;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Filet de non-régression partagé entre les deux tracks de remédiation
 * (FITSCORE_REMEDIATION.md §4 P0.5) — fige le comportement actuel du
 * calculateur sur le référentiel seedé par V42, pour que chaque track puisse
 * prouver qu'il n'a pas déplacé les scores de l'autre.
 *
 * <p><b>Ces valeurs ne sont pas des valeurs « correctes »</b> : plusieurs
 * encodent des bugs connus et documentés (F01, F02, F07, F08, F21). Les
 * corriger <i>doit</i> faire échouer ce test — c'est le but. Le contrat est :
 * tout écart avec cette baseline doit être <b>expliqué</b> dans le message de
 * commit, jamais simplement réaligné.
 *
 * <p><b>Écart du 2026-08-15, au titre de ce contrat.</b> Les cinq personas ont perdu
 * de 0 à 5 points, sans qu'aucune pondération ne bouge : « Je Décide » est devenu
 * mesurable et un <b>cinquième</b> module entre désormais dans leur moyenne pondérée.
 * L'infirmier senior perd le plus (75 -> 70) parce que sa prise de décision synthétisée
 * (50) est loin de sa régulation émotionnelle (93), qui pèse 45 % sur un profil
 * Relationnel. Le photographe ne perd rien : ses modules sont homogènes.
 */
class FitScoreBaselineTest {

    private final DeterministicFitScoreCalculator calculator = new DeterministicFitScoreCalculator();

    /** Le référentiel de V42__job_role_profiles.sql, recopié à l'identique. */
    private static JobRoleProfile profile(JobProfileType type, ExperienceLevel level) {
        int[] hardCurve;   // JUNIOR, SENIOR, LEAD, MANAGER
        int[] modules;     // flex, mémoire, décision, planification, régulation
        TypeEvaluationHard mode = TypeEvaluationHard.QCM;
        switch (type) {
            case TECHNIQUE     -> { hardCurve = new int[]{35, 65, 55, 30}; modules = new int[]{30, 20, 30, 15,  5}; }
            case ANALYTIQUE    -> { hardCurve = new int[]{30, 60, 50, 25}; modules = new int[]{25, 20, 30, 15, 10}; }
            case RELATIONNEL   -> { hardCurve = new int[]{10, 25, 20, 10}; modules = new int[]{10, 10, 20, 15, 45}; }
            case MANAGERIAL    -> { hardCurve = new int[]{20, 40, 35, 20}; modules = new int[]{10, 10, 20, 30, 30}; }
            case CONVENTIONNEL -> { hardCurve = new int[]{25, 40, 35, 20}; modules = new int[]{15, 30, 15, 30, 10}; }
            case ARTISTIQUE    -> { hardCurve = new int[]{30, 55, 45, 25}; modules = new int[]{40, 15, 15, 15, 15};
                                    mode = TypeEvaluationHard.PORTFOLIO; }
            default -> throw new IllegalStateException("Profil non couvert : " + type);
        }
        int hard = hardCurve[level.ordinal()];
        return new JobRoleProfile(type, level, 100 - hard, hard, hard,
            modules[0], modules[1], modules[2], modules[3], modules[4], false, Instant.now());
    }

    /**
     * Un candidat qui a joué <b>tous</b> les jeux livrés, module par module.
     *
     * <p>Ces personas mesurent la <i>pondération</i> métier, pas la décote de couverture :
     * ils doivent donc rester pleinement couverts. Avant la livraison Games du 2026-08-10,
     * un seul jeu par module suffisait pour cela — la flexibilité en compte désormais 3,
     * la mémoire 2, et « Je Décide » est mesurable depuis le 2026-08-12. Il faut les
     * alimenter tous pour garder la même signification. Sans ça les personas se seraient
     * mis à décrire des candidats qui sautent la moitié des jeux, et les scores de
     * référence auraient chuté sans qu'aucune pondération ne bouge.
     */
    private static Map<String, ModuleScore> measuredModules(double flex, double memory,
                                                            double planning, double regulation) {
        return measuredModules(flex, memory, planning, regulation, decision(flex, memory));
    }

    /**
     * Le score de « Je Décide » n'était pas un paramètre de ces personas tant que le
     * module était inatteignable. Plutôt que de réécrire les cinq personas et de perdre
     * la comparaison avec la baseline d'origine, la prise de décision reçoit la moyenne
     * des deux modules cognitifs les plus proches — un candidat n'est pas radicalement
     * différent sur cette dimension. Les tests qui veulent une valeur précise passent
     * par la surcharge à cinq arguments.
     */
    private static double decision(double flex, double memory) {
        return Math.round((flex + memory) / 2);
    }

    private static Map<String, ModuleScore> measuredModules(double flex, double memory,
                                                            double planning, double regulation,
                                                            double decision) {
        Map<String, ModuleScore> scores = new LinkedHashMap<>();
        scores.put("MOVE_FAST", ModuleScore.fullyCovered(flex));
        scores.put("CONTINUOUS_ATTENTION", ModuleScore.fullyCovered(flex));
        scores.put("VISUOMOTOR_COORDINATION", ModuleScore.fullyCovered(flex));
        scores.put("MEMORY_QUEST", ModuleScore.fullyCovered(memory));
        scores.put("VISUOSPATIAL_MEMORY", ModuleScore.fullyCovered(memory));
        scores.put("DECISION", ModuleScore.fullyCovered(decision));
        scores.put("PLANIFIK", ModuleScore.fullyCovered(planning));
        scores.put("EMOTIONAL_REGULATION", ModuleScore.fullyCovered(regulation));
        return scores;
    }

    private FitScoreResult score(Map<String, ModuleScore> modules, JobRoleProfile roleProfile, Integer hardScore) {
        return calculator.calculate(new FitScoreInputs(modules, roleProfile, hardScore));
    }

    @Test
    @DisplayName("Baseline : développeur senior, profil Technique, avec QCM")
    void developpeurSenior() {
        FitScoreResult result = score(measuredModules(82, 74, 90, 55),
            profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR), 78);

        assertThat(result.softSkillScore()).isEqualTo(79);
        assertThat(result.score()).isEqualTo(78);
    }

    @Test
    @DisplayName("Baseline : commercial junior, profil Relationnel, sans QCM — le fit égale le soft")
    void commercialJuniorSansQcm() {
        FitScoreResult result = score(measuredModules(60, 65, 58, 88),
            profile(JobProfileType.RELATIONNEL, ExperienceLevel.JUNIOR), null);

        assertThat(result.softSkillScore()).isEqualTo(73);
        assertThat(result.score()).isEqualTo(73).isEqualTo(result.softSkillScore());
    }

    @Test
    @DisplayName("Baseline : comptable manager, profil Conventionnel, avec QCM")
    void comptableManager() {
        FitScoreResult result = score(measuredModules(55, 84, 79, 70),
            profile(JobProfileType.CONVENTIONNEL, ExperienceLevel.MANAGER), 61);

        assertThat(result.softSkillScore()).isEqualTo(75);
        // F21 : le soft reste à virgule jusqu'au mélange final. Arrondi trop tôt, le fit
        // basculerait d'un point — c'est tout l'objet de ce garde-fou.
        assertThat(result.score()).isEqualTo(72);
    }

    @Test
    @DisplayName("Baseline : infirmier senior, profil Relationnel — la régulation émotionnelle pèse 45 %")
    void infirmierSenior() {
        FitScoreResult result = score(measuredModules(48, 52, 55, 93),
            profile(JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR), 64);

        assertThat(result.softSkillScore()).isEqualTo(70);
        assertThat(result.score()).isEqualTo(69);
    }

    @Test
    @DisplayName("Baseline : photographe lead, profil Artistique, portfolio seul (pas de QCM)")
    void photographeLead() {
        FitScoreResult result = score(measuredModules(95, 58, 54, 77),
            profile(JobProfileType.ARTISTIQUE, ExperienceLevel.LEAD), null);

        assertThat(result.softSkillScore()).isEqualTo(78);
        assertThat(result.score()).isEqualTo(78);
    }

    /**
     * D-A / F31 — garde-fou du renommage des niveaux. Le CdC §4.1 veut que le pic
     * du poids hard skills tombe sur SENIOR (« Senior / Expert : hard skills
     * dominant »), pas sur la bande d'avant. Un candidat fort au QCM et faible en
     * soft doit donc obtenir son meilleur score au niveau SENIOR.
     */
    @Test
    @DisplayName("D-A : le pic de pondération hard tombe bien sur SENIOR, pas ailleurs")
    void picHardSurSenior() {
        Map<String, ModuleScore> softFaible = measuredModules(45, 45, 45, 45);

        int junior  = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.JUNIOR),  90).score();
        int senior  = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR),  90).score();
        int lead    = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.LEAD),    90).score();
        int manager = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.MANAGER), 90).score();

        assertThat(senior).isGreaterThan(lead).isGreaterThan(junior).isGreaterThan(manager);
        assertThat(lead).isGreaterThan(junior).isGreaterThan(manager);
    }

    /**
     * F08 ✅ corrigé — la renormalisation sur les seuls modules joués est supprimée.
     * Avant, un candidat <b>gagnait 11 points</b> en ne jouant pas un mini-jeu qu'il
     * aurait raté : le poids du module manquant était redistribué sur les autres.
     * Un module disponible mais non joué reste désormais au dénominateur avec une
     * contribution nulle — jouer n'est jamais pénalisant.
     */
    @Test
    @DisplayName("F08 ✅ corrigé : sauter un mini-jeu raté fait BAISSER le score")
    void sauterUnMiniJeuRateFaitBaisserLeScore() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);
        Map<String, ModuleScore> joue = new LinkedHashMap<>();
        joue.put("MOVE_FAST", ModuleScore.fullyCovered(80));
        joue.put("MEMORY_QUEST", ModuleScore.fullyCovered(75));
        joue.put("PLANIFIK", ModuleScore.fullyCovered(30));   // mini-jeu raté
        Map<String, ModuleScore> saute = new LinkedHashMap<>(joue);
        saute.remove("PLANIFIK");

        int avecLeJeuRate = score(joue, technique, null).softSkillScore();
        int sansLeJeuRate = score(saute, technique, null).softSkillScore();

        assertThat(sansLeJeuRate).isLessThan(avecLeJeuRate);
        assertThat(avecLeJeuRate - sansLeJeuRate).isEqualTo(4);
    }

    /**
     * F01 ✅ corrigé. Une clé de module que {@code SoftSkillModule} ne connaît pas
     * était écartée de la boucle de pondération, puis <b>réintroduite</b> par le repli
     * {@code weightTotal == 0}, qui moyennait la map complète : elle devenait la
     * totalité du score soft, sans aucune pondération métier.
     */
    @Test
    @DisplayName("F01 ✅ corrigé : une clé de module inconnue n'entre plus dans le score")
    void cleDeModuleInconnueNEntrePlusDansLeScore() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);

        // Avant : le repli moyennait la map entière, clés rejetées comprises, et la
        // valeur inconnue devenait la totalité du Score_Soft (90 -> 90, 10 -> 10).
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(90)), technique, null)).isNull();
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(10)), technique, null)).isNull();

        // Mélangée à un module connu, elle reste ignorée : seul MOVE_FAST compte.
        // 40 × 0,33 × 30 / 100 = 4 — la valeur inconnue (90) n'y contribue en rien.
        // Move Fast est 1 des 3 jeux de la flexibilité, d'où la décote au tiers.
        Map<String, ModuleScore> melange = new LinkedHashMap<>();
        melange.put("MOVE_FAST", ModuleScore.fullyCovered(40));
        melange.put("JEU_PAS_ENCORE_CABLE", ModuleScore.fullyCovered(90));
        assertThat(score(melange, technique, null).softSkillScore()).isEqualTo(4);
        assertThat(score(Map.of("MOVE_FAST", ModuleScore.fullyCovered(40)), technique, null)
            .softSkillScore()).isEqualTo(4);
    }

    /**
     * Documente le bug F02 : l'absence totale de donnée soft est enregistrée comme
     * un 0 mesuré, puis servie au recruteur comme tel. Après correction, le
     * calculateur doit renvoyer {@code null} (rien à écrire), comme il le fait déjà
     * pour une offre sans métier approuvé.
     */
    @Test
    @DisplayName("F02 ✅ corrigé : aucune donnée soft n'est plus un score de 0")
    void aucuneDonneeSoftNEstPlusUnZero() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);

        // Avant : softSkillScore=0 persisté comme une mesure, fit=46 (0×35 % + 70×65 %),
        // servi au recruteur comme si le candidat avait été évalué et avait échoué.
        assertThat(score(Map.of(), technique, 70)).isNull();
        assertThat(score(Map.of(), technique, null)).isNull();
    }

    @Test
    @DisplayName("Offre sans métier approuvé : rien n'est calculé ni écrit")
    void offreSansMetierApprouve() {
        assertThat(score(measuredModules(90, 90, 90, 90), null, 78)).isNull();
    }
}
