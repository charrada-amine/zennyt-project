package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : annuler un recrutement confirmé (recruteur propriétaire). Refusé
 * une fois la période d'essai terminée — le recrutement est alors définitif.
 */
@Service
@RequiredArgsConstructor
public class CancelHireUseCase {

    private final JobOpportunityOfferRepository offers;

    @Transactional
    public JobOpportunityOffer execute(UUID recruiterId, UUID offerId) {
        JobOpportunityOffer offer = offers.findById(offerId)
            .orElseThrow(() -> new NotFoundException("Recrutement introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Ce recrutement ne vous appartient pas");
        }
        offer.cancel(Instant.now());
        return offers.save(offer);
    }
}
