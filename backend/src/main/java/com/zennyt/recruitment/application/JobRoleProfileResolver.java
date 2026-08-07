package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
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

    public JobRoleProfile resolve(JobOffer offer) {
        if (offer.jobPositionId() == null) return null;
        return positions.findById(offer.jobPositionId())
            .map(JobPosition::profileType)
            .filter(profileType -> profileType != null)
            .flatMap(profileType -> roleProfiles.findByProfileTypeAndLevel(profileType, offer.experienceLevel()))
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
        List<UUID> positionIds = offers.stream()
            .map(JobOffer::jobPositionId).filter(Objects::nonNull).distinct().toList();
        if (positionIds.isEmpty()) return Map.of();

        Map<UUID, JobProfileType> profileTypeByPosition = positions.findByIds(positionIds).stream()
            .filter(position -> position.profileType() != null)
            .collect(Collectors.toMap(JobPosition::id, JobPosition::profileType));
        Map<String, JobRoleProfile> weightsByTypeAndLevel = roleProfiles.findAll().stream()
            .collect(Collectors.toMap(
                profile -> key(profile.profileType(), profile.level()), Function.identity()));

        Map<UUID, JobRoleProfile> resolved = new HashMap<>();
        for (JobOffer offer : offers) {
            if (offer.jobPositionId() == null) continue;
            JobProfileType profileType = profileTypeByPosition.get(offer.jobPositionId());
            if (profileType == null) continue;
            JobRoleProfile weights = weightsByTypeAndLevel.get(key(profileType, offer.experienceLevel()));
            if (weights != null) resolved.put(offer.id(), weights);
        }
        return resolved;
    }

    private static String key(JobProfileType profileType, ExperienceLevel level) {
        return profileType.name() + '|' + level.name();
    }
}
