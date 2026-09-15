package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Cas d'usage : lister les recrutements (confirmés ou annulés) du recruteur. */
@Service
@RequiredArgsConstructor
public class ListHiredCandidatesUseCase {

    private final JobOpportunityOfferRepository offers;

    @Transactional(readOnly = true)
    public List<JobOpportunityOffer> execute(UUID recruiterId) {
        return offers.findByRecruiterIdAndStatusIn(recruiterId,
            List.of(JobOpportunityStatus.CONFIRMED, JobOpportunityStatus.CANCELLED));
    }
}
