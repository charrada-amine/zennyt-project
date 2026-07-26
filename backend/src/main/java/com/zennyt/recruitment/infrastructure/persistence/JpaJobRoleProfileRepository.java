package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface JpaJobRoleProfileRepository extends JpaRepository<JobRoleProfileEntity, UUID> {
    Optional<JobRoleProfileEntity> findByProfileTypeAndLevel(JobProfileType profileType, ExperienceLevel level);
}
