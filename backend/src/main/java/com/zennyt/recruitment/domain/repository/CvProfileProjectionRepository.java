package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.CvProfileProjection;

import java.util.Optional;
import java.util.UUID;

public interface CvProfileProjectionRepository {
    CvProfileProjection save(CvProfileProjection projection);
    Optional<CvProfileProjection> findByCandidateId(UUID candidateId);
}
