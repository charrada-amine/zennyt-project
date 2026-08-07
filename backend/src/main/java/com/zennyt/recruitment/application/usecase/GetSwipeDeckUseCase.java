package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.CandidateFeedRanker;
import com.zennyt.recruitment.application.InlineFitScoreComputer;
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

    /**
     * P4 — les candidats dont les compétences techniques ont été mesurées passent devant,
     * puis le score décroissant à l'intérieur de chaque groupe.
     *
     * <p>Ce n'est pas un confort d'affichage, c'est la correction d'une <b>inversion</b>.
     * Faute de test, le calculateur met {@code hardWeight} à 0 : le score d'un candidat non
     * évalué est son score soft brut, tandis que celui d'un candidat évalué est tiré vers
     * son résultat au test. Sur un métier TECHNIQUE / SENIOR ({@code hard_weight = 65}), un
     * candidat à 70 de soft sans test obtient 70 ; le même profil testé à 60 % obtient
     * 0,35×70 + 0,65×60 = 64. Le non testé passait donc devant l'évalué — sur un tri par
     * score seul, systématiquement.
     *
     * <p>Corriger par la formule reviendrait à pénaliser l'absence de donnée, ce que le CdC
     * interdit (une absence n'est pas un zéro). Le tri, lui, ne touche à aucun score : il
     * dit seulement lequel des deux repose sur une mesure complète.
     */
    private static final java.util.Comparator<FitScore> EVALUES_D_ABORD =
        java.util.Comparator.comparing((FitScore score) -> score.hardSkillScore() == null)
            .thenComparing(java.util.Comparator.comparingInt(FitScore::score).reversed());

    private final JobOfferRepository offers;
    private final FitScoreRepository fitScores;
    private final FitScoreDismissalRepository dismissals;
    private final CandidateFeedRanker ranker;
    private final InlineFitScoreComputer inlineComputer;
    private final int rankingPoolSize;

    public GetSwipeDeckUseCase(JobOfferRepository offers, FitScoreRepository fitScores,
                               FitScoreDismissalRepository dismissals, CandidateFeedRanker ranker,
                               InlineFitScoreComputer inlineComputer,
                               @Value("${recruitment.ranking.pool-size:200}") int rankingPoolSize) {
        this.offers = offers;
        this.fitScores = fitScores;
        this.dismissals = dismissals;
        this.ranker = ranker;
        this.inlineComputer = inlineComputer;
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
        // Calcule les notes manquantes avant le classement, pour qu'aucune offre affichée
        // ne soit reléguée en fin de liste faute de note. Sans effet si la fonctionnalité
        // est désactivée, et sans jamais faire échouer la requête (voir le composant).
        inlineComputer.ensureScored(candidateId, pool);
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
            .sorted(EVALUES_D_ABORD)
            .toList();
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, size);
        int from = Math.min(visible.size(), safePage * safeSize);
        int to = Math.min(visible.size(), from + safeSize);
        return new RecruiterDeck(visible.size(), visible.subList(from, to));
    }
}
