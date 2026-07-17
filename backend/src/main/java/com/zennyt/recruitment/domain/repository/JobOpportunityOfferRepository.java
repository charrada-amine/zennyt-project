package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.JobOpportunityOffer;

import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository d'offres d'opportunité.
 */
public interface JobOpportunityOfferRepository {

    JobOpportunityOffer save(JobOpportunityOffer offer);

    Optional<JobOpportunityOffer> findById(UUID id);
}
