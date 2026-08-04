package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
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
            modules[0], modules[1], modules[2], modules[3], modules[4], mode, false, Instant.now());
    }

    /** Les 4 modules réellement produits par Games depuis la livraison de « Je gère ». */
    private static Map<String, Double> measuredModules(double flex, double memory, double planning, double regulation) {
        Map<String, Double> scores = new LinkedHashMap<>();
        scores.put("MOVE_FAST", flex);
        scores.put("MEMORY_QUEST", memory);
        scores.put("PLANIFIK", planning);
        scores.put("EMOTIONAL_REGULATION", regulation);
        return scores;   // DECISION reste inatteignable : DECISION_CORE.playable() == false
    }

    private FitScoreResult score(Map<String, Double> modules, JobRoleProfile roleProfile, Integer hardScore) {
        return calculator.calculate(new FitScoreInputs(modules, "desc", "companyInfo", roleProfile, hardScore, 100));
    }

    @Test
    @DisplayName("Baseline : développeur senior, profil Technique, avec QCM")
    void developpeurSenior() {
        FitScoreResult result = score(measuredModules(82, 74, 90, 55),
            profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR), 78);

        assertThat(result.softSkillScore()).isEqualTo(80);
        assertThat(result.score()).isEqualTo(79);
    }

    @Test
    @DisplayName("Baseline : commercial junior, profil Relationnel, sans QCM — le fit égale le soft")
    void commercialJuniorSansQcm() {
        FitScoreResult result = score(measuredModules(60, 65, 58, 88),
            profile(JobProfileType.RELATIONNEL, ExperienceLevel.JUNIOR), null);

        assertThat(result.softSkillScore()).isEqualTo(76);
        assertThat(result.score()).isEqualTo(76).isEqualTo(result.softSkillScore());
    }

    @Test
    @DisplayName("Baseline : comptable manager, profil Conventionnel, avec QCM")
    void comptableManager() {
        FitScoreResult result = score(measuredModules(55, 84, 79, 70),
            profile(JobProfileType.CONVENTIONNEL, ExperienceLevel.MANAGER), 61);

        assertThat(result.softSkillScore()).isEqualTo(75);
        assertThat(result.score()).isEqualTo(72);
    }

    @Test
    @DisplayName("Baseline : infirmier senior, profil Relationnel — la régulation émotionnelle pèse 45 %")
    void infirmierSenior() {
        FitScoreResult result = score(measuredModules(48, 52, 55, 93),
            profile(JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR), 64);

        assertThat(result.softSkillScore()).isEqualTo(75);
        assertThat(result.score()).isEqualTo(72);
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
        Map<String, Double> softFaible = measuredModules(45, 45, 45, 45);

        int junior  = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.JUNIOR),  90).score();
        int senior  = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR),  90).score();
        int lead    = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.LEAD),    90).score();
        int manager = score(softFaible, profile(JobProfileType.TECHNIQUE, ExperienceLevel.MANAGER), 90).score();

        assertThat(senior).isGreaterThan(lead).isGreaterThan(junior).isGreaterThan(manager);
        assertThat(lead).isGreaterThan(junior).isGreaterThan(manager);
    }

    /**
     * Documente le bug F08 tel qu'il existe aujourd'hui : la renormalisation sur
     * les seuls modules joués fait qu'un candidat gagne des points en <b>ne jouant
     * pas</b> un mini-jeu qu'il raterait. Quand la décision D-D sera appliquée
     * (diviser par 100, module absent = 0), ce test doit être inversé :
     * jouer ne doit jamais être pénalisant.
     */
    @Test
    @DisplayName("F08 (bug connu) : sauter un mini-jeu raté fait AUGMENTER le score")
    void sauterUnMiniJeuRateAugmenteLeScore() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);
        Map<String, Double> joue = new LinkedHashMap<>();
        joue.put("MOVE_FAST", 80.0);
        joue.put("MEMORY_QUEST", 75.0);
        joue.put("PLANIFIK", 30.0);          // mini-jeu raté
        Map<String, Double> saute = new LinkedHashMap<>(joue);
        saute.remove("PLANIFIK");

        int avecLeJeuRate = score(joue, technique, null).softSkillScore();
        int sansLeJeuRate = score(saute, technique, null).softSkillScore();

        assertThat(sansLeJeuRate).isGreaterThan(avecLeJeuRate);
        assertThat(sansLeJeuRate - avecLeJeuRate).isEqualTo(11);
    }

    /**
     * Documente le bug F01. Une clé de module que {@code SoftSkillModule} ne
     * connaît pas est écartée de la boucle de pondération, puis <b>réintroduite</b>
     * par le repli {@code weightTotal == 0}, qui moyenne la map complète. Elle
     * devient alors la totalité du score soft, sans aucune pondération métier.
     */
    @Test
    @DisplayName("F01 (bug connu) : une clé de module inconnue devient tout le score soft")
    void cleDeModuleInconnueDevientToutLeScore() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);

        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", 90.0), technique, null).softSkillScore()).isEqualTo(90);
        assertThat(score(Map.of("JEU_PAS_ENCORE_CABLE", 10.0), technique, null).softSkillScore()).isEqualTo(10);
    }

    /**
     * Documente le bug F02 : l'absence totale de donnée soft est enregistrée comme
     * un 0 mesuré, puis servie au recruteur comme tel. Après correction, le
     * calculateur doit renvoyer {@code null} (rien à écrire), comme il le fait déjà
     * pour une offre sans métier approuvé.
     */
    @Test
    @DisplayName("F02 (bug connu) : aucune donnée soft est traitée comme un score de 0")
    void aucuneDonneeSoftEstTraiteeCommeUnZero() {
        JobRoleProfile technique = profile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR);

        FitScoreResult result = score(Map.of(), technique, 70);

        assertThat(result).isNotNull();
        assertThat(result.softSkillScore()).isZero();
        assertThat(result.score()).isEqualTo(46);   // 0 × 35 % + 70 × 65 %
    }

    @Test
    @DisplayName("Offre sans métier approuvé : rien n'est calculé ni écrit")
    void offreSansMetierApprouve() {
        assertThat(score(measuredModules(90, 90, 90, 90), null, 78)).isNull();
    }
}
