package com.zennyt.identity.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.Length;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Entity
@Table(name = "recruiter_onboarding_infos", uniqueConstraints =
    @UniqueConstraint(name = "recruiter_onboarding_infos_user_id_key", columnNames = {"user_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RecruiterOnboardingEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Clé étrangère {@code users(id)} ; lecture seule, la colonne est écrite via {@link #userId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "recruiter_onboarding_infos_user_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Getter(AccessLevel.NONE)
    private UserEntity user;
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
    @Column(name = "about_me", length = Length.LONG32)
    private String aboutMe;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public RecruiterOnboardingEntity(Long id, Long userId, String jobTitle, String companyName,
                                     String companySize, String companyLogoUrl,
                                     String companyLogoPublicId, String fieldOfWork,
                                     String companyLocation, String companyRegistrationNumber,
                                     String aboutMe, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.jobTitle = jobTitle;
        this.companyName = companyName;
        this.companySize = companySize;
        this.companyLogoUrl = companyLogoUrl;
        this.companyLogoPublicId = companyLogoPublicId;
        this.fieldOfWork = fieldOfWork;
        this.companyLocation = companyLocation;
        this.companyRegistrationNumber = companyRegistrationNumber;
        this.aboutMe = aboutMe;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
