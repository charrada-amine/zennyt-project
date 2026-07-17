package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class AssessmentAttemptAccessUseCase {
    private final AssessmentAttemptRepository attempts;
    private final JobOfferRepository jobOffers;

    public AssessmentAttemptAccessUseCase(AssessmentAttemptRepository attempts,
                                          JobOfferRepository jobOffers) {
        this.attempts = attempts;
        this.jobOffers = jobOffers;
    }

    public AssessmentAttempt getForActor(UUID attemptId, UUID actorId) {
        AssessmentAttempt attempt = attempts.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Tentative introuvable"));
        if (attempt.candidateId().equals(actorId)) {
            return attempt;
        }
        var offer = jobOffers.findById(attempt.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(actorId)) {
            throw new ForbiddenException("Cette tentative ne vous appartient pas");
        }
        return attempt;
    }

    public List<AssessmentAttempt> listForRecruiter(UUID jobOfferId, UUID recruiterId,
                                                     int page, int size) {
        var offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        return attempts.findByJobOfferId(jobOfferId, page, size);
    }
}
