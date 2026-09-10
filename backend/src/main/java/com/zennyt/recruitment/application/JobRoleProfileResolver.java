package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Résout la pondération (profil métier × niveau) d'une offre — {@code null} si
 * l'offre n'est pas encore reliée au référentiel de métiers, ou si le métier
 * n'a pas encore de profil assigné (proposition en attente d'approbation).
 */
@Component
public class JobRoleProfileResolver {
    private final JobPositionRepository positions;
    private final JobRoleProfileRepository roleProfiles;

    public JobRoleProfileResolver(JobPositionRepository positions, JobRoleProfileRepository roleProfiles) {
        this.positions = positions;
        this.roleProfiles = roleProfiles;
    }

    /**
     * Ce que le référentiel dit d'une offre : combien le technique pèse, et comment il se
     * mesure. Les deux viennent du même métier, donc de la même requête — les séparer
     * coûterait une lecture de plus par offre, ce que F20 venait justement de supprimer.
     *
     * @param weights        pondération du couple (profil, niveau)
     * @param evaluationMode mode d'évaluation du hard skills, porté par le MÉTIER depuis F32
     */
    public record ResolvedProfile(JobRoleProfile weights, TypeEvaluationHard evaluationMode) {}

    public JobRoleProfile resolve(JobOffer offer) {
        ResolvedProfile resolved = resolveWithEvaluationMode(offer);
        return resolved == null ? null : resolved.weights();
    }

    public ResolvedProfile resolveWithEvaluationMode(JobOffer offer) {
        if (offer.jobPositionId() == null) return null;
        return positions.findById(offer.jobPositionId())
            .filter(position -> position.profileType() != null)
            .flatMap(position -> roleProfiles
                .findByProfileTypeAndLevel(position.profileType(), offer.experienceLevel())
                .map(weights -> new ResolvedProfile(weights, position.typeEvaluationHard())))
            .orElse(null);
    }

    /**
     * Variante par lot de {@link #resolve} — deux requêtes au total quel que soit le nombre
     * d'offres, au lieu de deux par offre. Le référentiel de pondération étant fixe
     * (24 lignes, 6 profils × 4 niveaux), il est chargé intégralement puis indexé en mémoire.
     *
     * @return la pondération par {@code jobOfferId} ; une offre absente de la map est une
     *         offre non résolue (pas de métier, ou métier pas encore validé par un admin) —
     *         même sémantique que le {@code null} de {@link #resolve}.
     */
    public Map<UUID, JobRoleProfile> resolveAll(List<JobOffer> offers) {
        return resolveAllWithEvaluationMode(offers).entrySet().stream()
            .collect(Collectors.toMap(Map.Entry::getKey, entry -> entry.getValue().weights()));
    }

    /** Variante par lot de {@link #resolveWithEvaluationMode}, même coût que {@link #resolveAll}. */
    public Map<UUID, ResolvedProfile> resolveAllWithEvaluationMode(List<JobOffer> offers) {
        List<UUID> positionIds = offers.stream()
            .map(JobOffer::jobPositionId).filter(Objects::nonNull).distinct().toList();
        if (positionIds.isEmpty()) return Map.of();

        Map<UUID, JobPosition> positionsById = positions.findByIds(positionIds).stream()
            .filter(position -> position.profileType() != null)
            .collect(Collectors.toMap(JobPosition::id, Function.identity()));
        Map<String, JobRoleProfile> weightsByTypeAndLevel = roleProfiles.findAll().stream()
            .collect(Collectors.toMap(
                profile -> key(profile.profileType(), profile.level()), Function.identity()));

        Map<UUID, ResolvedProfile> resolved = new HashMap<>();
        for (JobOffer offer : offers) {
            if (offer.jobPositionId() == null) continue;
            JobPosition position = positionsById.get(offer.jobPositionId());
            if (position == null) continue;
            JobRoleProfile weights = weightsByTypeAndLevel
                .get(key(position.profileType(), offer.experienceLevel()));
            if (weights != null) {
                resolved.put(offer.id(), new ResolvedProfile(weights, position.typeEvaluationHard()));
            }
        }
        return resolved;
    }

    private static String key(JobProfileType profileType, ExperienceLevel level) {
        return profileType.name() + '|' + level.name();
    }
}
