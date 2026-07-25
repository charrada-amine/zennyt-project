package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JobPositionRepository {
    JobPosition save(JobPosition position);
    Optional<JobPosition> findById(UUID id);
    /** @param sector optionnel — null renvoie tous les secteurs (et les métiers transverses) */
    List<JobPosition> findByStatus(JobPositionStatus status, String sector);
    boolean existsByNameAndSector(String name, String sector);
}
