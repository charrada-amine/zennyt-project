package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository d'offres d'opportunité.
 */
public interface JobOpportunityOfferRepository {

    JobOpportunityOffer save(JobOpportunityOffer offer);

    Optional<JobOpportunityOffer> findById(UUID id);

    /** Recrutements d'un recruteur, filtrés par statut (ex. CONFIRMED + CANCELLED). */
    List<JobOpportunityOffer> findByRecruiterIdAndStatusIn(
        UUID recruiterId, Collection<JobOpportunityStatus> statuses);
}
