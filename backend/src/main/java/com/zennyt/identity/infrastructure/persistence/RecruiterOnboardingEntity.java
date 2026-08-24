package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "recruiter_onboarding_infos")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
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
    @Column(name = "company_logo_public_id", length = 255)
    private String companyLogoPublicId;
    @Column(name = "field_of_work", nullable = false, length = 150)
    private String fieldOfWork;
    @Column(name = "company_location", nullable = false, length = 150)
    private String companyLocation;
    @Column(name = "company_registration_number", nullable = false, length = 100)
    private String companyRegistrationNumber;
    @Column(name = "about_me")
    private String aboutMe;
    @Column(name = "about", columnDefinition = "TEXT")
    private String about;
    @Column(name = "mission", columnDefinition = "TEXT")
    private String mission;
    @Column(name = "vision", columnDefinition = "TEXT")
    private String vision;
    @Column(name = "key_differentiators", columnDefinition = "TEXT")
    private String keyDifferentiators;
    @Column(name = "culture_work_environment", columnDefinition = "TEXT")
    private String cultureWorkEnvironment;
    @Column(name = "why_join_us", columnDefinition = "TEXT")
    private String whyJoinUs;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
