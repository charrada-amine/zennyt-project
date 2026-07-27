package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class RecruitmentActorRepositoryAdapter implements RecruitmentActorRepository {
    private final JpaRecruitmentActorRepository jpa;

    @Override
    public Optional<RecruitmentActor> findById(UUID publicUserId) {
        return jpa.findById(publicUserId).map(this::toDomain);
    }

    @Override
    public RecruitmentActor save(RecruitmentActor actor) {
        RecruitmentActorEntity entity = new RecruitmentActorEntity(
            actor.publicUserId(), actor.role(), actor.active(),
            actor.fullName(), actor.avatarUrl(), actor.city(), actor.country(),
            actor.companyName(), actor.companyInfo(),
            actor.workplaceTypePreference(), actor.contractTypePreference(),
            actor.targetLocation(), actor.openInternationally(),
            actor.yearsOfExperience(), actor.lookingFor(), actor.lookingForEmbedding(),
            actor.lastEventAt(), actor.lastEventId());
        return toDomain(jpa.save(entity));
    }

    private RecruitmentActor toDomain(RecruitmentActorEntity entity) {
        return new RecruitmentActor(entity.getPublicUserId(), entity.getRole(), entity.isActive(),
            entity.getFullName(), entity.getAvatarUrl(), entity.getCity(), entity.getCountry(),
            entity.getCompanyName(), entity.getCompanyInfo(),
            entity.getWorkplaceTypePreference(), entity.getContractTypePreference(),
            entity.getTargetLocation(), entity.getOpenInternationally(),
            entity.getYearsOfExperience(), entity.getLookingFor(), entity.getLookingForEmbedding(),
            entity.getLastEventAt(), entity.getLastEventId());
    }

    @Override
    public List<MatchingDeckCandidate> findMatchingDeckForJobOffer(UUID jobOfferId, int page, int size) {
        return jpa.findMatchingDeckForJobOffer(jobOfferId, PageRequest.of(page, size)).stream()
            .map(row -> new MatchingDeckCandidate(toDomain((RecruitmentActorEntity) row[0]),
                row[1] == SwipeDirection.RIGHT))
            .toList();
    }

    @Override
    public long countMatchingDeckForJobOffer(UUID jobOfferId) {
        return jpa.countMatchingDeckForJobOffer(jobOfferId);
    }
}
