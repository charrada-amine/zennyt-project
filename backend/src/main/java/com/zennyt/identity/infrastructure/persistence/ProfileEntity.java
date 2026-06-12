package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.*;
import jakarta.persistence.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Entity
@Table(name = "profiles")
public class ProfileEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;
    @Column(name = "current_position", length = 150)
    private String currentPosition;
    @Column(name = "looking_for", length = 150)
    private String lookingFor;
    @Enumerated(EnumType.STRING)
    @Column(name = "type_of_workplace", length = 20)
    private WorkplaceType workplaceType;
    @Enumerated(EnumType.STRING)
    @Column(name = "type_of_job", length = 20)
    private JobType jobType;
    @Column(name = "target_job_location", length = 150)
    private String targetJobLocation;
    @Column(name = "years_of_experience")
    private Integer yearsOfExperience;
    @Column(name = "soft_skills_score")
    private Integer softSkillsScore;
    @Column(name = "about_me", columnDefinition = "TEXT")
    private String aboutMe;
    @Column(name = "is_open_internationally", nullable = false)
    private boolean openInternationally;
    @Enumerated(EnumType.STRING)
    @Column(name = "availability_type", length = 20)
    private AvailabilityType availabilityType;
    @Column(name = "availability_date")
    private LocalDate availabilityDate;
    @Column(name = "resume_ai_url", length = 500)
    private String resumeAiUrl;
    @Column(name = "portfolio_url", length = 500)
    private String portfolioUrl;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @OneToMany(mappedBy = "profile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SkillEntity> skills = new ArrayList<>();
    @OneToMany(mappedBy = "profile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PositionEntity> positions = new ArrayList<>();
    @OneToMany(mappedBy = "profile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CertificationEntity> certifications = new ArrayList<>();
    @OneToMany(mappedBy = "profile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<EducationEntity> education = new ArrayList<>();

    protected ProfileEntity() {}

    public ProfileEntity(Profile profile) {
        this.userId = profile.userId();
        this.createdAt = profile.createdAt();
        updateFields(profile);
        profile.skills().forEach(value -> skills.add(new SkillEntity(this, value)));
        profile.positions().forEach(value -> positions.add(new PositionEntity(this, value)));
        profile.certifications().forEach(value -> certifications.add(new CertificationEntity(this, value)));
        profile.education().forEach(value -> education.add(new EducationEntity(this, value)));
    }

    void updateFrom(Profile profile) {
        updateFields(profile);
        syncSkills(profile);
        syncPositions(profile);
        syncCertifications(profile);
        syncEducation(profile);
    }

    private void updateFields(Profile profile) {
        this.currentPosition = profile.currentPosition();
        this.lookingFor = profile.lookingFor();
        this.workplaceType = profile.workplaceType();
        this.jobType = profile.jobType();
        this.targetJobLocation = profile.targetJobLocation();
        this.yearsOfExperience = profile.yearsOfExperience();
        this.softSkillsScore = profile.softSkillsScore();
        this.aboutMe = profile.aboutMe();
        this.openInternationally = profile.openInternationally();
        this.availabilityType = profile.availabilityType();
        this.availabilityDate = profile.availabilityDate();
        this.resumeAiUrl = profile.resumeAiUrl();
        this.portfolioUrl = profile.portfolioUrl();
        this.updatedAt = profile.updatedAt();
    }

    private void syncSkills(Profile profile) {
        skills.removeIf(entity -> profile.skills().stream()
            .noneMatch(value -> Objects.equals(value.id(), entity.getId())));
        profile.skills().forEach(value -> {
            if (value.id() == null) {
                skills.add(new SkillEntity(this, value));
            } else {
                skills.stream().filter(entity -> Objects.equals(entity.getId(), value.id()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Compétence introuvable"))
                    .updateFrom(value);
            }
        });
    }

    private void syncPositions(Profile profile) {
        positions.removeIf(entity -> profile.positions().stream()
            .noneMatch(value -> Objects.equals(value.id(), entity.getId())));
        profile.positions().forEach(value -> {
            if (value.id() == null) {
                positions.add(new PositionEntity(this, value));
            } else {
                positions.stream().filter(entity -> Objects.equals(entity.getId(), value.id()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Poste introuvable"))
                    .updateFrom(value);
            }
        });
    }

    private void syncCertifications(Profile profile) {
        certifications.removeIf(entity -> profile.certifications().stream()
            .noneMatch(value -> Objects.equals(value.id(), entity.getId())));
        profile.certifications().forEach(value -> {
            if (value.id() == null) {
                certifications.add(new CertificationEntity(this, value));
            } else {
                certifications.stream()
                    .filter(entity -> Objects.equals(entity.getId(), value.id()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Certification introuvable"))
                    .updateFrom(value);
            }
        });
    }

    private void syncEducation(Profile profile) {
        education.removeIf(entity -> profile.education().stream()
            .noneMatch(value -> Objects.equals(value.id(), entity.getId())));
        profile.education().forEach(value -> {
            if (value.id() == null) {
                education.add(new EducationEntity(this, value));
            } else {
                education.stream().filter(entity -> Objects.equals(entity.getId(), value.id()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Formation introuvable"))
                    .updateFrom(value);
            }
        });
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getCurrentPosition() { return currentPosition; }
    public String getLookingFor() { return lookingFor; }
    public WorkplaceType getWorkplaceType() { return workplaceType; }
    public JobType getJobType() { return jobType; }
    public String getTargetJobLocation() { return targetJobLocation; }
    public Integer getYearsOfExperience() { return yearsOfExperience; }
    public Integer getSoftSkillsScore() { return softSkillsScore; }
    public String getAboutMe() { return aboutMe; }
    public boolean isOpenInternationally() { return openInternationally; }
    public AvailabilityType getAvailabilityType() { return availabilityType; }
    public LocalDate getAvailabilityDate() { return availabilityDate; }
    public String getResumeAiUrl() { return resumeAiUrl; }
    public String getPortfolioUrl() { return portfolioUrl; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public List<SkillEntity> getSkills() { return skills; }
    public List<PositionEntity> getPositions() { return positions; }
    public List<CertificationEntity> getCertifications() { return certifications; }
    public List<EducationEntity> getEducation() { return education; }
}
