package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.CandidateFeedRanker;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.beans.factory.annotation.Value;
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
    private final CandidateFeedRanker ranker;
    private final int rankingPoolSize;

    public GetSwipeDeckUseCase(JobOfferRepository offers, FitScoreRepository fitScores,
                               FitScoreDismissalRepository dismissals, CandidateFeedRanker ranker,
                               @Value("${recruitment.ranking.pool-size:200}") int rankingPoolSize) {
        this.offers = offers;
        this.fitScores = fitScores;
        this.dismissals = dismissals;
        this.ranker = ranker;
        this.rankingPoolSize = rankingPoolSize;
    }

    /**
     * Récupère un pool d'offres plus large que la page demandée, le réordonne
     * par pertinence (voir {@link CandidateFeedRanker}), puis pagine en mémoire —
     * le tri SQL brut (Fit Score puis date) ne suffit plus une fois les
     * préférences candidat et la similarité sémantique prises en compte.
     */
    public List<JobOffer> candidateOffers(UUID candidateId, int page, int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, size);
        int poolSize = Math.max(rankingPoolSize, (safePage + 1) * safeSize);
        List<JobOffer> pool = offers.findFeedForCandidate(candidateId, 0, poolSize);
        List<JobOffer> ranked = ranker.rank(candidateId, pool);
        int from = Math.min(ranked.size(), safePage * safeSize);
        int to = Math.min(ranked.size(), from + safeSize);
        return ranked.subList(from, to);
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
