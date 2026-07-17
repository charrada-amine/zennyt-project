package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.IdentityVerification;
import com.zennyt.recruitment.domain.repository.IdentityVerificationRepository;
import org.springframework.stereotype.Component;
import java.util.Optional;
import java.util.UUID;

@Component
public class IdentityVerificationRepositoryAdapter implements IdentityVerificationRepository {
    private final JpaIdentityVerificationRepository jpa;
    public IdentityVerificationRepositoryAdapter(JpaIdentityVerificationRepository jpa) { this.jpa = jpa; }

    @Override public IdentityVerification save(IdentityVerification v) { return toDomain(jpa.save(toEntity(v))); }
    @Override public Optional<IdentityVerification> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    private IdentityVerificationEntity toEntity(IdentityVerification v) {
        IdentityVerificationEntity e = new IdentityVerificationEntity();
        e.setId(v.id()); e.setRequestedByRecruiterId(v.requestedByRecruiterId());
        e.setTargetCandidateId(v.targetCandidateId()); e.setJobOfferId(v.jobOfferId());
        e.setStatus(v.status()); e.setRequestedAt(v.requestedAt()); e.setResolvedAt(v.resolvedAt());
        return e;
    }

    private IdentityVerification toDomain(IdentityVerificationEntity e) {
        return IdentityVerification.rehydrate(e.getId(), e.getRequestedByRecruiterId(),
            e.getTargetCandidateId(), e.getJobOfferId(), e.getStatus(), e.getRequestedAt(), e.getResolvedAt());
    }
}
