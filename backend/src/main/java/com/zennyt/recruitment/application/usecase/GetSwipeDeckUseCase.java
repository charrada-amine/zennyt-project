package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Feed bidirectionnel : offres pour candidat, candidats fit-scorés pour recruteur. */
@Service
@Transactional(readOnly = true)
public class GetSwipeDeckUseCase {
    public record RecruiterDeck(long totalElements, List<FitScore> content) {}

    private final JobOfferRepository offers;
    private final FitScoreRepository fitScores;
    private final FitScoreDismissalRepository dismissals;

    public GetSwipeDeckUseCase(JobOfferRepository offers, FitScoreRepository fitScores,
                               FitScoreDismissalRepository dismissals) {
        this.offers = offers;
        this.fitScores = fitScores;
        this.dismissals = dismissals;
    }

    public List<JobOffer> candidateOffers(UUID candidateId, int page, int size) {
        return offers.findFeedForCandidate(candidateId, page, size);
    }

    public RecruiterDeck recruiterCandidates(UUID recruiterId, UUID jobOfferId, int page, int size) {
        JobOffer offer = offers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        List<FitScore> visible = fitScores.findByJobOfferIdOrderByScoreDesc(jobOfferId).stream()
            .filter(score -> !dismissals.isDismissed(
                recruiterId, score.candidateId(), jobOfferId))
            .toList();
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, size);
        int from = Math.min(visible.size(), safePage * safeSize);
        int to = Math.min(visible.size(), from + safeSize);
        return new RecruiterDeck(visible.size(), visible.subList(from, to));
    }
}
