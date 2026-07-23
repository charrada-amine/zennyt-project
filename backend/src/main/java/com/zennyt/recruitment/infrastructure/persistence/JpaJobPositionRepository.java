package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface JpaJobPositionRepository extends JpaRepository<JobPositionEntity, UUID> {
    List<JobPositionEntity> findByStatusAndSector(JobPositionStatus status, String sector);
    List<JobPositionEntity> findByStatus(JobPositionStatus status);
    boolean existsByNameAndSector(String name, String sector);
}
