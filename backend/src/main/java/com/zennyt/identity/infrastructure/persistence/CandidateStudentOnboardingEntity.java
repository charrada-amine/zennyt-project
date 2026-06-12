package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "candidate_student_onboarding_infos")
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

    protected CandidateStudentOnboardingEntity() {}

    public CandidateStudentOnboardingEntity(Long id, Long userId, String school,
                                             String educationLevel, String fieldOfWork,
                                             String lastPositionHeld, Integer yearsOfExperience,
                                             String cvFileUrl, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.school = school;
        this.educationLevel = educationLevel;
        this.fieldOfWork = fieldOfWork;
        this.lastPositionHeld = lastPositionHeld;
        this.yearsOfExperience = yearsOfExperience;
        this.cvFileUrl = cvFileUrl;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getSchool() { return school; }
    public String getEducationLevel() { return educationLevel; }
    public String getFieldOfWork() { return fieldOfWork; }
    public String getLastPositionHeld() { return lastPositionHeld; }
    public Integer getYearsOfExperience() { return yearsOfExperience; }
    public String getCvFileUrl() { return cvFileUrl; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
