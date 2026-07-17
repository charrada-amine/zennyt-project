package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.vo.SalaryRange;
import org.springframework.stereotype.Component;
import java.util.Optional;
import java.util.UUID;

@Component
public class JobOpportunityOfferRepositoryAdapter implements JobOpportunityOfferRepository {
    private final JpaJobOpportunityOfferRepository jpa;
    public JobOpportunityOfferRepositoryAdapter(JpaJobOpportunityOfferRepository jpa) { this.jpa = jpa; }

    @Override public JobOpportunityOffer save(JobOpportunityOffer o) { return toDomain(jpa.save(toEntity(o))); }
    @Override public Optional<JobOpportunityOffer> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    private JobOpportunityOfferEntity toEntity(JobOpportunityOffer o) {
        JobOpportunityOfferEntity e = new JobOpportunityOfferEntity();
        e.setId(o.id()); e.setRecruiterId(o.recruiterId()); e.setCandidateId(o.candidateId());
        e.setJobOfferId(o.jobOfferId()); e.setTitle(o.title());
        if (o.salary() != null) { e.setSalaryMin(o.salary().min()); e.setSalaryMax(o.salary().max()); e.setSalaryCurrency(o.salary().currency()); }
        e.setStatus(o.status()); e.setOtpVerified(o.otpVerified()); e.setSentAt(o.sentAt()); e.setRespondedAt(o.respondedAt());
        return e;
    }

    private JobOpportunityOffer toDomain(JobOpportunityOfferEntity e) {
        SalaryRange sal = (e.getSalaryMin() != null && e.getSalaryMax() != null && e.getSalaryCurrency() != null)
            ? new SalaryRange(e.getSalaryMin(), e.getSalaryMax(), e.getSalaryCurrency()) : null;
        return JobOpportunityOffer.rehydrate(e.getId(), e.getRecruiterId(), e.getCandidateId(),
            e.getJobOfferId(), e.getTitle(), sal, e.getStatus(), e.isOtpVerified(), e.getSentAt(), e.getRespondedAt());
    }
}
