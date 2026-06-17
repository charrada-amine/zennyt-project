package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "candidate_student_onboarding_infos")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class CandidateStudentOnboardingEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;
    @Column(length = 150)
    private String school;
    @Column(name = "education_level", length = 150)
    private String educationLevel;
    @Column(name = "field_of_work", length = 150)
    private String fieldOfWork;
    @Column(name = "last_position_held", length = 150)
    private String lastPositionHeld;
    @Column(name = "years_of_experience")
    private Integer yearsOfExperience;
    @Column(name = "cv_file_url", length = 500)
    private String cvFileUrl;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
