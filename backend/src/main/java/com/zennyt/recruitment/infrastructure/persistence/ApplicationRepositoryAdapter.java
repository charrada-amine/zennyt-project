package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.Map;
import java.util.HashMap;

@Component
public class ApplicationRepositoryAdapter implements ApplicationRepository {

    private final JpaApplicationRepository jpa;

    public ApplicationRepositoryAdapter(JpaApplicationRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Application save(Application a) {
        ApplicationEntity entity = toEntity(a);
        return toDomain(jpa.save(entity));
    }

    @Override
    public Optional<Application> findById(UUID id) {
        return jpa.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<Application> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.findByCandidateIdAndJobOfferId(candidateId, jobOfferId).map(this::toDomain);
    }

    @Override
    public boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.existsByCandidateIdAndJobOfferId(candidateId, jobOfferId);
    }

    @Override
    public List<Application> findByCandidateId(UUID candidateId, ApplicationStatus status, int page, int size) {
        var pageable = PageRequest.of(page, size);
        var result = status != null
            ? jpa.findByCandidateIdAndStatus(candidateId, status, pageable)
            : jpa.findByCandidateId(candidateId, pageable);
        return result.map(this::toDomain).getContent();
    }

    @Override
    public List<Application> findByJobOfferId(UUID jobOfferId, ApplicationStatus status, int page, int size) {
        var pageable = PageRequest.of(page, size);
        var result = status != null
            ? jpa.findByJobOfferIdAndStatus(jobOfferId, status, pageable)
            : jpa.findByJobOfferId(jobOfferId, pageable);
        return result.map(this::toDomain).getContent();
    }

    @Override
    public long countByCandidateId(UUID candidateId, ApplicationStatus status) {
        return status != null
            ? jpa.countByCandidateIdAndStatus(candidateId, status)
            : jpa.countByCandidateId(candidateId);
    }

    @Override
    public long countByJobOfferId(UUID jobOfferId, ApplicationStatus status) {
        return status != null
            ? jpa.countByJobOfferIdAndStatus(jobOfferId, status)
            : jpa.countByJobOfferId(jobOfferId);
    }

    @Override
    public Map<UUID, Long> countByJobOfferIds(List<UUID> jobOfferIds) {
        if (jobOfferIds.isEmpty()) return Map.of();
        Map<UUID, Long> counts = new HashMap<>();
        for (Object[] row : jpa.countGroupedByJobOfferId(jobOfferIds)) {
            counts.put((UUID) row[0], (Long) row[1]);
        }
        return counts;
    }

    private ApplicationEntity toEntity(Application a) {
        return new ApplicationEntity(a.id(), a.candidateId(), a.jobOfferId(),
            a.status(), a.appliedAt(), a.updatedAt());
    }

    private Application toDomain(ApplicationEntity e) {
        return Application.rehydrate(e.getId(), e.getCandidateId(), e.getJobOfferId(),
            e.getStatus(), e.getAppliedAt(), e.getUpdatedAt());
    }
}
