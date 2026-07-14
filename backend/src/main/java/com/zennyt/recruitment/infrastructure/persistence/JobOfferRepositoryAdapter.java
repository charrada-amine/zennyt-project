package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.List;
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
    public long countByRecruiterId(UUID recruiterId, JobOfferStatus status) {
        return status != null ? jpa.countByRecruiterIdAndStatus(recruiterId, status) : jpa.countByRecruiterId(recruiterId);
    }

    @Override
    public List<JobOffer> search(String query, String location, String contractType,
                                  String workplaceType, String experienceLevel, String fieldOfWork,
                                  Double salaryMin, Double salaryMax, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by("postedAt").descending());
        return jpa.search(query, location, contractType, experienceLevel, pageable)
            .map(this::toDomain).getContent();
    }

    @Override
    public long countSearch(String query, String location, String contractType,
                            String workplaceType, String experienceLevel, String fieldOfWork,
                            Double salaryMin, Double salaryMax) {
        return jpa.search(query, location, contractType, experienceLevel, PageRequest.of(0, 1)).getTotalElements();
    }

    @Override
    public List<JobOffer> findFeedForCandidate(UUID candidateId, int page, int size) {
        // Pour l'instant : retourne les offres ACTIVE triées par date
        return jpa.findByStatus(JobOfferStatus.ACTIVE, PageRequest.of(page, size, Sort.by("postedAt").descending()))
            .map(this::toDomain).getContent();
    }

    @Override
    public long countFeedForCandidate(UUID candidateId) {
        return jpa.count();
    }

    // ───────────── Mappers ─────────────
    private JobOfferEntity toEntity(JobOffer o) {
        JobOfferEntity e = new JobOfferEntity();
        e.setId(o.id()); e.setRecruiterId(o.recruiterId()); e.setHiringContactId(o.hiringContactId());
        e.setTitle(o.title()); e.setCompanyName(o.companyName());
        if (o.location() != null) {
            e.setLocationCity(o.location().city()); e.setLocationCountry(o.location().country());
            e.setLocationRemote(o.location().remote());
        }
        if (o.salary() != null) {
            e.setSalaryMin(o.salary().min()); e.setSalaryMax(o.salary().max());
            e.setSalaryCurrency(o.salary().currency());
        }
        e.setContractType(o.contractType()); e.setWorkplaceType(o.workplaceType());
        e.setExperienceLevel(o.experienceLevel()); e.setFieldOfWork(o.fieldOfWork());
        e.setDescription(o.description()); e.setResponsibilities(o.responsibilities());
        e.setMinimumQualifications(o.minimumQualifications()); e.setPreferredQualifications(o.preferredQualifications());
        e.setWhatWeOffer(o.whatWeOffer()); e.setHowToApply(o.howToApply()); e.setCompanyInfo(o.companyInfo());
        e.setAssessmentId(o.assessmentId());
        e.setOpenToInternational(o.openToInternational()); e.setStatus(o.status()); e.setPostedAt(o.postedAt());
        return e;
    }

    private JobOffer toDomain(JobOfferEntity e) {
        Location loc = new Location(e.getLocationCity(), e.getLocationCountry(), e.isLocationRemote());
        SalaryRange sal = (e.getSalaryMin() != null && e.getSalaryMax() != null && e.getSalaryCurrency() != null)
            ? new SalaryRange(e.getSalaryMin(), e.getSalaryMax(), e.getSalaryCurrency()) : null;
        return JobOffer.rehydrate(e.getId(), e.getRecruiterId(), e.getHiringContactId(),
            e.getTitle(), e.getCompanyName(), loc, sal, e.getContractType(), e.getWorkplaceType(),
            e.getExperienceLevel(), e.getFieldOfWork(), e.getDescription(), e.getResponsibilities(),
            e.getMinimumQualifications(), e.getPreferredQualifications(), e.getWhatWeOffer(),
            e.getHowToApply(), e.getCompanyInfo(), e.getAssessmentId(), e.isOpenToInternational(),
            e.getStatus(), e.getPostedAt());
    }
}
