package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class CvProfileProjectionRepositoryAdapter implements CvProfileProjectionRepository {
    private final JpaCvProfileProjectionRepository jpa;

    public CvProfileProjectionRepositoryAdapter(JpaCvProfileProjectionRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public CvProfileProjection save(CvProfileProjection projection) {
        return toDomain(jpa.save(new CvProfileProjectionEntity(
            projection.candidateId(), projection.cvText(), projection.updatedAt())));
    }

    @Override
    public Optional<CvProfileProjection> findByCandidateId(UUID candidateId) {
        return jpa.findById(candidateId).map(this::toDomain);
    }

    private CvProfileProjection toDomain(CvProfileProjectionEntity entity) {
        return new CvProfileProjection(entity.getCandidateId(), entity.getCvText(), entity.getUpdatedAt());
    }
}
