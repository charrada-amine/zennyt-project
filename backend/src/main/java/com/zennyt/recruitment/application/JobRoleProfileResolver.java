package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import org.springframework.stereotype.Component;

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
}
