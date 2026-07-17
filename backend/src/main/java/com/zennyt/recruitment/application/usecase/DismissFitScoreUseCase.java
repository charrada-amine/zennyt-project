package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/** Masque idempotemment une paire de la vue Fit Scores d'un recruteur. */
@Service
@Transactional
public class DismissFitScoreUseCase {
    private final JobOfferRepository offers;
    private final FitScoreDismissalRepository dismissals;

    public DismissFitScoreUseCase(JobOfferRepository offers,
                                  FitScoreDismissalRepository dismissals) {
        this.offers = offers;
        this.dismissals = dismissals;
    }

    public void execute(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        var offer = offers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        dismissals.dismiss(recruiterId, candidateId, jobOfferId, Instant.now());
    }
}
