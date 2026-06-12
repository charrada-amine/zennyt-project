package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.CandidateStudentOnboarding;
import com.zennyt.identity.domain.model.RecruiterOnboarding;

import java.util.Optional;

public interface OnboardingRepository {
    CandidateStudentOnboarding saveCandidateStudent(CandidateStudentOnboarding onboarding);
    Optional<CandidateStudentOnboarding> findCandidateStudentByUserId(Long userId);
    RecruiterOnboarding saveRecruiter(RecruiterOnboarding onboarding);
    Optional<RecruiterOnboarding> findRecruiterByUserId(Long userId);
}
