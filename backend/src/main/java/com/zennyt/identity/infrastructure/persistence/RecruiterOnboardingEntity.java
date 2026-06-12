package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "recruiter_onboarding_infos")
public class RecruiterOnboardingEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;
    @Column(name = "job_title", nullable = false, length = 150)
    private String jobTitle;
    @Column(name = "company_name", nullable = false, length = 150)
    private String companyName;
    @Column(name = "company_size", nullable = false, length = 100)
    private String companySize;
    @Column(name = "company_logo_url", length = 500)
    private String companyLogoUrl;
    @Column(name = "field_of_work", nullable = false, length = 150)
    private String fieldOfWork;
    @Column(name = "company_location", nullable = false, length = 150)
    private String companyLocation;
    @Column(name = "company_registration_number", nullable = false, length = 100)
    private String companyRegistrationNumber;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected RecruiterOnboardingEntity() {}

    public RecruiterOnboardingEntity(Long id, Long userId, String jobTitle, String companyName,
                                     String companySize, String companyLogoUrl, String fieldOfWork,
                                     String companyLocation, String companyRegistrationNumber,
                                     Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.jobTitle = jobTitle;
        this.companyName = companyName;
        this.companySize = companySize;
        this.companyLogoUrl = companyLogoUrl;
        this.fieldOfWork = fieldOfWork;
        this.companyLocation = companyLocation;
        this.companyRegistrationNumber = companyRegistrationNumber;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getJobTitle() { return jobTitle; }
    public String getCompanyName() { return companyName; }
    public String getCompanySize() { return companySize; }
    public String getCompanyLogoUrl() { return companyLogoUrl; }
    public String getFieldOfWork() { return fieldOfWork; }
    public String getCompanyLocation() { return companyLocation; }
    public String getCompanyRegistrationNumber() { return companyRegistrationNumber; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
