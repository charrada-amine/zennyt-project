package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface JpaJobOpportunityOfferRepository extends JpaRepository<JobOpportunityOfferEntity, UUID> {

    List<JobOpportunityOfferEntity> findByRecruiterIdAndStatusInOrderByRespondedAtDesc(
        UUID recruiterId, Collection<JobOpportunityStatus> statuses);
}
