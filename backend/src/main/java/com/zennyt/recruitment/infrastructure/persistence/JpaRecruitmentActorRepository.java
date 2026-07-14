package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface JpaRecruitmentActorRepository
        extends JpaRepository<RecruitmentActorEntity, UUID> {
}
