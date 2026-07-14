package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface JpaAssessmentRepository extends JpaRepository<AssessmentEntity, UUID> {
    Page<AssessmentEntity> findByCreatedByRecruiterId(UUID recruiterId, Pageable pageable);
    long countByCreatedByRecruiterId(UUID recruiterId);
    List<AssessmentEntity> findByIdIn(List<UUID> ids);
}
