package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.RecruitmentActor;

import java.util.Optional;
import java.util.UUID;

public interface RecruitmentActorRepository {
    Optional<RecruitmentActor> findById(UUID publicUserId);
    RecruitmentActor save(RecruitmentActor actor);
}
