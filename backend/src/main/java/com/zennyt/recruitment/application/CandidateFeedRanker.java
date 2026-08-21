package com.zennyt.recruitment.application;

import com.zennyt.shared.application.EmbeddingCodec;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.Location;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Réordonne le pool d'offres candidates par pertinence — voir plan
 * "Recommended for you". Le Fit Score reste le signal dominant : une offre
 * sans score ne passe jamais devant une offre scorée (règle inchangée, sujet
 * séparé). À l'intérieur de chaque groupe (scoré / non scoré), un bonus
 * s'ajoute pour les préférences respectées (contrat, télétravail,
 * localisation, international) et pour la proximité sémantique entre le
 * "rôle recherché" du candidat et le métier de l'offre — jamais un filtre
 * bloquant, une préférence absente ne compte ni en bonus ni en pénalité.
 */
@Component
public class CandidateFeedRanker {

    private final RecruitmentActorRepository actors;
    private final FitScoreRepository fitScores;
    private final JobPositionRepository positions;
    private final double criterionBonus;
    private final double semanticWeight;

    public CandidateFeedRanker(RecruitmentActorRepository actors, FitScoreRepository fitScores,
                               JobPositionRepository positions,
                               @Value("${recruitment.ranking.criterion-bonus:2.0}") double criterionBonus,
                               @Value("${recruitment.ranking.semantic-weight:2.0}") double semanticWeight) {
        this.actors = actors;
        this.fitScores = fitScores;
        this.positions = positions;
        this.criterionBonus = criterionBonus;
        this.semanticWeight = semanticWeight;
    }

    public List<JobOffer> rank(UUID candidateId, List<JobOffer> pool) {
        if (pool.isEmpty()) return pool;
        RecruitmentActor actor = actors.findById(candidateId).orElse(null);
        List<UUID> offerIds = pool.stream().map(JobOffer::id).toList();
        Map<UUID, FitScore> scoreByOfferId = fitScores.findByCandidateIdAndJobOfferIds(candidateId, offerIds).stream()
            .collect(Collectors.toMap(FitScore::jobOfferId, Function.identity()));
        Map<UUID, JobPosition> positionById = loadPositions(pool);

        Map<UUID, Double> bonusByOfferId = new HashMap<>();
        List<JobOffer> withScore = new ArrayList<>();
        List<JobOffer> withoutScore = new ArrayList<>();
        for (JobOffer offer : pool) {
            bonusByOfferId.put(offer.id(), bonus(actor, offer, positionById));
            (scoreByOfferId.containsKey(offer.id()) ? withScore : withoutScore).add(offer);
        }

        withScore.sort(Comparator.comparingDouble(
            (JobOffer o) -> scoreByOfferId.get(o.id()).score() + bonusByOfferId.get(o.id())).reversed());
        withoutScore.sort(Comparator.comparingDouble((JobOffer o) -> bonusByOfferId.get(o.id())).reversed());

        List<JobOffer> ranked = new ArrayList<>(withScore.size() + withoutScore.size());
        ranked.addAll(withScore);
        ranked.addAll(withoutScore);
        return ranked;
    }

    private Map<UUID, JobPosition> loadPositions(List<JobOffer> pool) {
        List<UUID> ids = pool.stream().map(JobOffer::jobPositionId).filter(Objects::nonNull).distinct().toList();
        if (ids.isEmpty()) return Map.of();
        return positions.findByIds(ids).stream().collect(Collectors.toMap(JobPosition::id, Function.identity()));
    }

    private double bonus(RecruitmentActor actor, JobOffer offer, Map<UUID, JobPosition> positionById) {
        if (actor == null) return 0;
        return criteriaMatches(actor, offer) * criterionBonus
            + semanticSimilarity(actor, offer, positionById) * semanticWeight;
    }

    private int criteriaMatches(RecruitmentActor actor, JobOffer offer) {
        int matches = 0;
        if (actor.workplaceTypePreference() != null && actor.workplaceTypePreference() == offer.workplaceType()) matches++;
        if (actor.contractTypePreference() != null && actor.contractTypePreference() == offer.contractType()) matches++;
        if (matchesLocation(actor.targetLocation(), offer.location())) matches++;
        if (actor.openInternationally() != null && actor.openInternationally().equals(offer.openToInternational())) matches++;
        return matches;
    }

    private boolean matchesLocation(String targetLocation, Location offerLocation) {
        if (targetLocation == null || targetLocation.isBlank() || offerLocation == null) return false;
        String target = targetLocation.trim().toLowerCase();
        String city = offerLocation.city() != null ? offerLocation.city().trim().toLowerCase() : "";
        String country = offerLocation.country() != null ? offerLocation.country().trim().toLowerCase() : "";
        return (!city.isBlank() && (target.contains(city) || city.contains(target)))
            || (!country.isBlank() && (target.contains(country) || country.contains(target)));
    }

    private double semanticSimilarity(RecruitmentActor actor, JobOffer offer, Map<UUID, JobPosition> positionById) {
        if (offer.jobPositionId() == null) return 0;
        JobPosition position = positionById.get(offer.jobPositionId());
        if (position == null) return 0;
        Double similarity = EmbeddingCodec.cosineSimilarity(
            EmbeddingCodec.fromJson(actor.lookingForEmbedding()), EmbeddingCodec.fromJson(position.embedding()));
        return similarity != null ? similarity : 0;
    }
}
