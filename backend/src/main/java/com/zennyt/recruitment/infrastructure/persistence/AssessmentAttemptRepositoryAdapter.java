package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class AssessmentAttemptRepositoryAdapter implements AssessmentAttemptRepository {
    private final JpaAssessmentAttemptRepository jpa;
    public AssessmentAttemptRepositoryAdapter(JpaAssessmentAttemptRepository jpa) { this.jpa = jpa; }

    @Override public AssessmentAttempt save(AssessmentAttempt a) { return toDomain(jpa.save(toEntity(a))); }
    @Override public Optional<AssessmentAttempt> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }
    @Override public boolean existsByCandidateIdAndAssessmentIdAndJobOfferId(UUID c, UUID a, UUID j) {
        return jpa.existsByCandidateIdAndAssessmentIdAndJobOfferId(c, a, j);
    }
    @Override public List<AssessmentAttempt> findByJobOfferId(UUID jobOfferId, int page, int size) {
        return jpa.findByJobOfferId(jobOfferId, PageRequest.of(page, size)).map(this::toDomain).getContent();
    }
    @Override public long countByJobOfferId(UUID jobOfferId) { return jpa.countByJobOfferId(jobOfferId); }

    private AssessmentAttemptEntity toEntity(AssessmentAttempt a) {
        return new AssessmentAttemptEntity(a.id(), a.assessmentId(), a.candidateId(), a.jobOfferId(), a.score(), a.passed(), a.integrityStatus(), a.submittedAt());
    }
    private AssessmentAttempt toDomain(AssessmentAttemptEntity e) {
        return AssessmentAttempt.rehydrate(e.getId(), e.getAssessmentId(), e.getCandidateId(), e.getJobOfferId(), e.getScore(), e.isPassed(), e.getIntegrityStatus(), e.getSubmittedAt());
    }
}
