package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Component
public class JobOfferRepositoryAdapter implements JobOfferRepository {

    private final JpaJobOfferRepository jpa;

    public JobOfferRepositoryAdapter(JpaJobOfferRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public JobOffer save(JobOffer o) { return toDomain(jpa.save(toEntity(o))); }

    @Override
    public Optional<JobOffer> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    @Override
    public void deleteById(UUID id) { jpa.deleteById(id); }

    @Override
    public List<JobOffer> findByRecruiterId(UUID recruiterId, JobOfferStatus status, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by("postedAt").descending());
        var result = status != null
            ? jpa.findByRecruiterIdAndStatus(recruiterId, status, pageable)
            : jpa.findByRecruiterId(recruiterId, pageable);
        return result.map(this::toDomain).getContent();
    }

    @Override
    public boolean existsByAssessmentId(UUID assessmentId) { return jpa.existsByAssessmentId(assessmentId); }

    @Override
    public List<UUID> findIdsByAssessmentId(UUID assessmentId) { return jpa.findIdsByAssessmentId(assessmentId); }

    @Override
    public Map<UUID, Long> countByAssessmentIds(List<UUID> assessmentIds) {
        if (assessmentIds.isEmpty()) return Map.of();
        Map<UUID, Long> counts = new HashMap<>();
        for (Object[] row : jpa.countGroupedByAssessmentId(assessmentIds)) {
            counts.put((UUID) row[0], (Long) row[1]);
        }
        return counts;
    }

    @Override
    public long countByRecruiterId(UUID recruiterId, JobOfferStatus status) {
        return status != null ? jpa.countByRecruiterIdAndStatus(recruiterId, status) : jpa.countByRecruiterId(recruiterId);
    }

    @Override
    public List<JobOffer> search(String query, String location, String contractType,
                                  String workplaceType, String experienceLevel, String fieldOfWork,
                                  Double salaryMin, Double salaryMax, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by("postedAt").descending());
        return jpa.search(query, location, toEnum(ContractType.class, contractType),
                toEnum(ExperienceLevel.class, experienceLevel), pageable)
            .map(this::toDomain).getContent();
    }

    @Override
    public long countSearch(String query, String location, String contractType,
                            String workplaceType, String experienceLevel, String fieldOfWork,
                            Double salaryMin, Double salaryMax) {
        return jpa.search(query, location, toEnum(ContractType.class, contractType),
                toEnum(ExperienceLevel.class, experienceLevel), PageRequest.of(0, 1)).getTotalElements();
    }

    /** Filtre invalide → filtre ignoré plutôt que 500 (comportement de recherche permissif). */
    private static <E extends Enum<E>> E toEnum(Class<E> type, String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Enum.valueOf(type, value.toUpperCase());
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    @Override
    public List<JobOffer> findFeedForCandidate(UUID candidateId, int page, int size) {
        return jpa.findFeedForCandidate(candidateId, PageRequest.of(page, size))
            .map(this::toDomain).getContent();
    }

    @Override
    public long countFeedForCandidate(UUID candidateId) {
        return jpa.countByStatus(JobOfferStatus.ACTIVE);
    }

    @Override
    public List<MatchingDeckOffer> findMatchingDeckForCandidate(UUID candidateId, int page, int size) {
        return jpa.findMatchingDeckForCandidate(candidateId, PageRequest.of(page, size)).stream()
            .map(row -> new MatchingDeckOffer(toDomain((JobOfferEntity) row[0]),
                row[1] == SwipeDirection.RIGHT))
            .toList();
    }

    @Override
    public long countMatchingDeckForCandidate(UUID candidateId) {
        return jpa.countMatchingDeckForCandidate(candidateId);
    }

    // ───────────── Mappers ─────────────
    private JobOfferEntity toEntity(JobOffer o) {
        JobOfferEntity e = new JobOfferEntity();
        e.setId(o.id()); e.setRecruiterId(o.recruiterId()); e.setHiringContactId(o.hiringContactId());
        e.setTitle(o.title());
        if (o.location() != null) {
            e.setLocationCity(o.location().city()); e.setLocationCountry(o.location().country());
        }
        e.setSalaryMin(o.salaryMin()); e.setSalaryMax(o.salaryMax());
        e.setContractType(o.contractType()); e.setWorkplaceType(o.workplaceType());
        e.setExperienceLevel(o.experienceLevel());
        e.setDescription(o.description()); e.setResponsibilities(o.responsibilities());
        e.setMinimumQualifications(o.minimumQualifications()); e.setPreferredQualifications(o.preferredQualifications());
        e.setWhatWeOffer(o.whatWeOffer()); e.setHowToApply(o.howToApply());
        e.setAssessmentId(o.assessmentId());
        e.setJobPositionId(o.jobPositionId());
        e.setOpenToInternational(o.openToInternational()); e.setStatus(o.status()); e.setPostedAt(o.postedAt());
        e.setUpdatedAt(o.updatedAt());
        return e;
    }

    private JobOffer toDomain(JobOfferEntity e) {
        Location loc = new Location(e.getLocationCity(), e.getLocationCountry());
        return JobOffer.rehydrate(e.getId(), e.getRecruiterId(), e.getHiringContactId(),
            e.getTitle(), loc, e.getSalaryMin(), e.getSalaryMax(), e.getContractType(), e.getWorkplaceType(),
            e.getExperienceLevel(), e.getDescription(), e.getResponsibilities(),
            e.getMinimumQualifications(), e.getPreferredQualifications(), e.getWhatWeOffer(),
            e.getHowToApply(), e.getAssessmentId(), e.getJobPositionId(),
            e.isOpenToInternational(),
            e.getStatus(), e.getPostedAt(), e.getUpdatedAt());
    }
}
