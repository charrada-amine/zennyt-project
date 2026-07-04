package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.CandidateStudentOnboarding;
import com.zennyt.identity.domain.model.RecruiterOnboarding;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class OnboardingRepositoryAdapter implements OnboardingRepository {
    private final JpaCandidateStudentOnboardingRepository candidateStudentJpa;
    private final JpaRecruiterOnboardingRepository recruiterJpa;

    @Override
    public CandidateStudentOnboarding saveCandidateStudent(CandidateStudentOnboarding value) {
        CandidateStudentOnboardingEntity saved = candidateStudentJpa.save(
            new CandidateStudentOnboardingEntity(value.id(), value.userId(), value.school(),
                value.educationLevel(), value.fieldOfWork(), value.lastPositionHeld(),
                value.yearsOfExperience(), value.cvFileUrl(), value.createdAt(), value.updatedAt()));
        return toDomain(saved);
    }

    @Override
    public Optional<CandidateStudentOnboarding> findCandidateStudentByUserId(Long userId) {
        return candidateStudentJpa.findByUserId(userId).map(this::toDomain);
    }

    @Override
    public RecruiterOnboarding saveRecruiter(RecruiterOnboarding value) {
        RecruiterOnboardingEntity saved = recruiterJpa.save(new RecruiterOnboardingEntity(
            value.id(), value.userId(), value.jobTitle(), value.companyName(), value.companySize(),
            value.companyLogoUrl(), value.companyLogoPublicId(), value.fieldOfWork(),
            value.companyLocation(), value.companyRegistrationNumber(), value.aboutMe(), value.createdAt(),
            value.updatedAt()));
        return toDomain(saved);
    }

    @Override
    public Optional<RecruiterOnboarding> findRecruiterByUserId(Long userId) {
        return recruiterJpa.findByUserId(userId).map(this::toDomain);
    }

    private CandidateStudentOnboarding toDomain(CandidateStudentOnboardingEntity value) {
        return new CandidateStudentOnboarding(value.getId(), value.getUserId(), value.getSchool(),
            value.getEducationLevel(), value.getFieldOfWork(), value.getLastPositionHeld(),
            value.getYearsOfExperience(), value.getCvFileUrl(), value.getCreatedAt(),
            value.getUpdatedAt());
    }

    private RecruiterOnboarding toDomain(RecruiterOnboardingEntity value) {
        return new RecruiterOnboarding(value.getId(), value.getUserId(), value.getJobTitle(),
            value.getCompanyName(), value.getCompanySize(), value.getCompanyLogoUrl(),
            value.getCompanyLogoPublicId(), value.getFieldOfWork(), value.getCompanyLocation(),
            value.getCompanyRegistrationNumber(), value.getAboutMe(), value.getCreatedAt(), value.getUpdatedAt());
    }
}
