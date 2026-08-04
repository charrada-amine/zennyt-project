package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.HardSkillsAlertLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.Test;

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

    @Test
    void artistiqueProfileAlwaysHasInfoAlertRegardlessOfExpectedHardWeight() {
        JobRoleProfile profile = new JobRoleProfile(JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR,
            45, 55, 55, 40, 15, 15, 15, 15, TypeEvaluationHard.PORTFOLIO, false, java.time.Instant.now());

        assertThat(profile.hardSkillsAlert()).isEqualTo(HardSkillsAlertLevel.INFO);
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
}
