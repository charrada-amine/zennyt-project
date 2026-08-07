package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;

import java.util.List;
import java.util.Optional;

/** Port du référentiel de pondération (24 lignes, profil × niveau — voir {@link JobRoleProfile}). */
public interface JobRoleProfileRepository {
    Optional<JobRoleProfile> findByProfileTypeAndLevel(JobProfileType profileType, ExperienceLevel level);
    List<JobRoleProfile> findAll();
}
