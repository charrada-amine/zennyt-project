package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class JobRoleProfileRepositoryAdapter implements JobRoleProfileRepository {
    private final JpaJobRoleProfileRepository jpa;

    public JobRoleProfileRepositoryAdapter(JpaJobRoleProfileRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Optional<JobRoleProfile> findByProfileTypeAndLevel(JobProfileType profileType, ExperienceLevel level) {
        return jpa.findByProfileTypeAndLevel(profileType, level).map(this::toDomain);
    }

    @Override
    public List<JobRoleProfile> findAll() {
        return jpa.findAll().stream().map(this::toDomain).toList();
    }

    private JobRoleProfile toDomain(JobRoleProfileEntity e) {
        return new JobRoleProfile(e.getProfileType(), e.getLevel(), e.getSoftWeight(), e.getHardWeight(),
            e.getExpectedHardWeight(), e.getCognitiveFlexibilityWeight(), e.getWorkingMemoryWeight(),
            e.getDecisionMakingWeight(), e.getExecutivePlanningWeight(), e.getEmotionalRegulationWeight(),
            e.getTypeEvaluationHard(), e.isCalibrated(), e.getUpdatedAt());
    }
}
