package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.HardSkillsAlertLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.time.Instant;
import java.util.EnumMap;
import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JobRoleProfileTest {

    @Test
    void softAndHardWeightsMustSumToOneHundred() {
        assertThatThrownBy(() -> new JobRoleProfile(JobProfileType.TECHNIQUE, ExperienceLevel.LEAD,
            50, 40, 40, 30, 20, 30, 15, 5, TypeEvaluationHard.QCM, false, java.time.Instant.now()))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void moduleWeightsMustSumToOneHundred() {
        assertThatThrownBy(() -> new JobRoleProfile(JobProfileType.TECHNIQUE, ExperienceLevel.LEAD,
            35, 65, 65, 30, 20, 30, 15, 4, TypeEvaluationHard.QCM, false, java.time.Instant.now()))
            .isInstanceOf(IllegalArgumentException.class);
    }

    /**
     * F19 (FITSCORE_REMEDIATION.md §3 index F19) — ARTISTIQUE porte un jeton
     * dédié PORTFOLIO_BASED, distinct d'INFO, pour que le client ne le
     * confonde plus avec « pensez à ajouter un QCM » (voir hardSkillsAlert()).
     */
    @Test
    void artistiqueProfileAlwaysHasPortfolioBasedAlertRegardlessOfExpectedHardWeight() {
        JobRoleProfile profile = new JobRoleProfile(JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR,
            45, 55, 55, 40, 15, 15, 15, 15, TypeEvaluationHard.PORTFOLIO, false, java.time.Instant.now());

        assertThat(profile.hardSkillsAlert()).isEqualTo(HardSkillsAlertLevel.PORTFOLIO_BASED);
    }

    @Test
    void nonArtistiqueAlertLevelIsBucketedByExpectedHardWeight() {
        JobRoleProfile relationnelJunior = new JobRoleProfile(JobProfileType.RELATIONNEL, ExperienceLevel.JUNIOR,
            90, 10, 10, 10, 10, 20, 15, 45, TypeEvaluationHard.QCM, false, java.time.Instant.now());
        JobRoleProfile managerialMid = new JobRoleProfile(JobProfileType.MANAGERIAL, ExperienceLevel.SENIOR,
            60, 40, 40, 10, 10, 20, 30, 30, TypeEvaluationHard.QCM, false, java.time.Instant.now());
        JobRoleProfile technicalMid = new JobRoleProfile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR,
            35, 65, 65, 30, 20, 30, 15, 5, TypeEvaluationHard.QCM, false, java.time.Instant.now());

        assertThat(relationnelJunior.hardSkillsAlert()).isEqualTo(HardSkillsAlertLevel.NONE);
        assertThat(managerialMid.hardSkillsAlert()).isEqualTo(HardSkillsAlertLevel.MODERATE);
        assertThat(technicalMid.hardSkillsAlert()).isEqualTo(HardSkillsAlertLevel.STRONG);
    }

    /**
     * F05 (FITSCORE_REMEDIATION.md §2 décision D-B, §3 index F05) — pin l'alerte
     * attendue des 24 lignes seedées (V42 + renommage de niveaux V53) pour éviter
     * toute régression silencieuse sur la borne INFO/MODERATE ou le plancher
     * MANAGER. Avant le correctif, 12 de ces 24 assertions échouaient :
     * TECHNIQUE/JUNIOR (poids 35) tombait en MODERATE au lieu d'INFO, et les 5
     * profils non-artistiques de niveau MANAGER tombaient en INFO/NONE au lieu de
     * MODERATE.
     */
    @ParameterizedTest(name = "{0}/{1} (poids hard={2}) -> {3}")
    @MethodSource("seededRoleProfiles")
    void alertMatchesSeededMatrix(JobProfileType profileType, ExperienceLevel level,
                                   int expectedHardWeight, HardSkillsAlertLevel expectedAlert) {
        JobRoleProfile profile = profileOf(profileType, level, expectedHardWeight);

        assertThat(profile.hardSkillsAlert()).isEqualTo(expectedAlert);
    }

    private static Stream<Arguments> seededRoleProfiles() {
        return Stream.of(
            // TECHNIQUE — courbe hard 35/65/55/30 (V42 + V53)
            Arguments.of(JobProfileType.TECHNIQUE, ExperienceLevel.JUNIOR, 35, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 65, HardSkillsAlertLevel.STRONG),
            Arguments.of(JobProfileType.TECHNIQUE, ExperienceLevel.LEAD, 55, HardSkillsAlertLevel.STRONG),
            Arguments.of(JobProfileType.TECHNIQUE, ExperienceLevel.MANAGER, 30, HardSkillsAlertLevel.MODERATE),
            // ANALYTIQUE — courbe hard 30/60/50/25
            Arguments.of(JobProfileType.ANALYTIQUE, ExperienceLevel.JUNIOR, 30, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.ANALYTIQUE, ExperienceLevel.SENIOR, 60, HardSkillsAlertLevel.STRONG),
            Arguments.of(JobProfileType.ANALYTIQUE, ExperienceLevel.LEAD, 50, HardSkillsAlertLevel.STRONG),
            Arguments.of(JobProfileType.ANALYTIQUE, ExperienceLevel.MANAGER, 25, HardSkillsAlertLevel.MODERATE),
            // RELATIONNEL — courbe hard 10/25/20/10
            Arguments.of(JobProfileType.RELATIONNEL, ExperienceLevel.JUNIOR, 10, HardSkillsAlertLevel.NONE),
            Arguments.of(JobProfileType.RELATIONNEL, ExperienceLevel.SENIOR, 25, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.RELATIONNEL, ExperienceLevel.LEAD, 20, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.RELATIONNEL, ExperienceLevel.MANAGER, 10, HardSkillsAlertLevel.MODERATE),
            // MANAGERIAL — courbe hard 20/40/35/20
            Arguments.of(JobProfileType.MANAGERIAL, ExperienceLevel.JUNIOR, 20, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.MANAGERIAL, ExperienceLevel.SENIOR, 40, HardSkillsAlertLevel.MODERATE),
            Arguments.of(JobProfileType.MANAGERIAL, ExperienceLevel.LEAD, 35, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.MANAGERIAL, ExperienceLevel.MANAGER, 20, HardSkillsAlertLevel.MODERATE),
            // CONVENTIONNEL — courbe hard 25/40/35/20
            Arguments.of(JobProfileType.CONVENTIONNEL, ExperienceLevel.JUNIOR, 25, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.CONVENTIONNEL, ExperienceLevel.SENIOR, 40, HardSkillsAlertLevel.MODERATE),
            Arguments.of(JobProfileType.CONVENTIONNEL, ExperienceLevel.LEAD, 35, HardSkillsAlertLevel.INFO),
            Arguments.of(JobProfileType.CONVENTIONNEL, ExperienceLevel.MANAGER, 20, HardSkillsAlertLevel.MODERATE),
            // ARTISTIQUE — toujours PORTFOLIO_BASED (F19), courbe hard 30/55/45/25
            Arguments.of(JobProfileType.ARTISTIQUE, ExperienceLevel.JUNIOR, 30, HardSkillsAlertLevel.PORTFOLIO_BASED),
            Arguments.of(JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR, 55, HardSkillsAlertLevel.PORTFOLIO_BASED),
            Arguments.of(JobProfileType.ARTISTIQUE, ExperienceLevel.LEAD, 45, HardSkillsAlertLevel.PORTFOLIO_BASED),
            Arguments.of(JobProfileType.ARTISTIQUE, ExperienceLevel.MANAGER, 25, HardSkillsAlertLevel.PORTFOLIO_BASED)
        );
    }

    /**
     * F28 (FITSCORE_REMEDIATION.md §3 index F28) — {@code JobRoleProfileTest} ne
     * couvrait auparavant que les deux sommes de poids et le bucketing d'alerte ;
     * rien n'assurait que la courbe hard skills garde sa forme (pic au niveau
     * SENIOR, décroissance jusqu'à MANAGER, JUNIOR sous le pic). Un chiffre
     * transposé dans une future migration — ou dans la recalibration RH à venir
     * — passerait silencieusement sans ce test. Réutilise {@link
     * #seededRoleProfiles()}, seule source de vérité de la matrice V42+V53
     * partagée avec F05, pour ne pas dupliquer les 24 poids.
     */
    @org.junit.jupiter.api.Test
    void seededMatrixHas24RowsWithHardWeightPeakingAtSeniorThenDecreasing() {
        Map<JobProfileType, Map<ExperienceLevel, Integer>> hardWeightByProfile =
            new EnumMap<>(JobProfileType.class);
        seededRoleProfiles().forEach(args -> {
            Object[] a = args.get();
            hardWeightByProfile
                .computeIfAbsent((JobProfileType) a[0], t -> new EnumMap<>(ExperienceLevel.class))
                .put((ExperienceLevel) a[1], (Integer) a[2]);
        });

        assertThat(hardWeightByProfile).hasSize(JobProfileType.values().length);
        for (JobProfileType profileType : JobProfileType.values()) {
            Map<ExperienceLevel, Integer> curve = hardWeightByProfile.get(profileType);
            assertThat(curve).as("%s : les 4 niveaux doivent être seedés", profileType)
                .containsOnlyKeys(ExperienceLevel.values());
            int junior = curve.get(ExperienceLevel.JUNIOR);
            int senior = curve.get(ExperienceLevel.SENIOR);
            int lead = curve.get(ExperienceLevel.LEAD);
            int manager = curve.get(ExperienceLevel.MANAGER);

            assertThat(senior).as("%s : le pic hard est au niveau SENIOR (CdC §4.1)", profileType)
                .isGreaterThan(junior).isGreaterThan(lead).isGreaterThan(manager);
            assertThat(lead).as("%s : décroissance après le pic, SENIOR > LEAD > MANAGER", profileType)
                .isGreaterThan(manager);
        }
    }

    /** Poids de module par profil (V42) — non pertinents pour l'alerte, juste requis par l'invariant du record. */
    private static JobRoleProfile profileOf(JobProfileType profileType, ExperienceLevel level, int hardWeight) {
        TypeEvaluationHard mode = profileType == JobProfileType.ARTISTIQUE
            ? TypeEvaluationHard.PORTFOLIO : TypeEvaluationHard.QCM;
        int[] modules = switch (profileType) {
            case TECHNIQUE -> new int[] {30, 20, 30, 15, 5};
            case ANALYTIQUE -> new int[] {25, 20, 30, 15, 10};
            case RELATIONNEL -> new int[] {10, 10, 20, 15, 45};
            case MANAGERIAL -> new int[] {10, 10, 20, 30, 30};
            case CONVENTIONNEL -> new int[] {15, 30, 15, 30, 10};
            case ARTISTIQUE -> new int[] {40, 15, 15, 15, 15};
        };
        return new JobRoleProfile(profileType, level, 100 - hardWeight, hardWeight, hardWeight,
            modules[0], modules[1], modules[2], modules[3], modules[4], mode, false, Instant.now());
    }
}
