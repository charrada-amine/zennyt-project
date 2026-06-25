package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class ProfileRepositoryAdapter implements ProfileRepository {
    private final JpaProfileRepository jpa;

    @Override
    public Profile save(Profile profile) {
        if (profile.id() == null) {
            return toDomain(jpa.saveAndFlush(new ProfileEntity(profile)));
        }
        ProfileEntity entity = jpa.findById(profile.id())
            .orElseThrow(() -> new IllegalArgumentException("Profil introuvable"));
        entity.updateFrom(profile);
        jpa.flush();
        return toDomain(entity);
    }

    @Override
    public Optional<Profile> findByUserId(Long userId) {
        return jpa.findByUserId(userId).map(this::toDomain);
    }

    @Override
    public Optional<Profile> findById(Long id) {
        return jpa.findById(id).map(this::toDomain);
    }

    private Profile toDomain(ProfileEntity value) {
        return Profile.rehydrate(value.getId(), value.getUserId(), value.getCurrentPosition(),
            value.getLookingFor(), value.getWorkplaceType(), value.getJobType(),
            value.getTargetJobLocation(), value.getYearsOfExperience(), value.getSoftSkillsScore(),
            value.getAboutMe(), value.isOpenInternationally(), value.getAvailabilityType(),
            value.getAvailabilityDate(), value.getResumeAiUrl(), value.getPortfolioUrl(),
            value.getCvUrl(), value.getCvPublicId(),
            value.getCreatedAt(), value.getUpdatedAt(),
            value.getSkills().stream().map(SkillEntity::toDomain).toList(),
            value.getPositions().stream().map(PositionEntity::toDomain).toList(),
            value.getCertifications().stream().map(CertificationEntity::toDomain).toList(),
            value.getEducation().stream().map(EducationEntity::toDomain).toList());
    }
}
