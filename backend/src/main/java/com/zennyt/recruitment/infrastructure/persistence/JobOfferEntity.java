package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.*;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/** Entité JPA pour la table job_offers. */
@Entity
@Table(name = "job_offers", schema = "recruitment")
public class JobOfferEntity {

    @Id
    private UUID id;

    @Column(nullable = false) private UUID recruiterId;
    private UUID hiringContactId;
    @Column(nullable = false) private String title;
    private String companyName;
    private String locationCity;
    private String locationCountry;
    private boolean locationRemote;
    private Double salaryMin;
    private Double salaryMax;
    private String salaryCurrency;

    @Enumerated(EnumType.STRING) @Column(nullable = false) private ContractType contractType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private WorkplaceType workplaceType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private ExperienceLevel experienceLevel;

    private String fieldOfWork;
    @Column(columnDefinition = "TEXT") private String description;
    @Column(columnDefinition = "TEXT") private String responsibilities;
    @Column(columnDefinition = "TEXT") private String minimumQualifications;
    @Column(columnDefinition = "TEXT") private String preferredQualifications;
    @Column(columnDefinition = "TEXT") private String whatWeOffer;
    @Column(columnDefinition = "TEXT") private String howToApply;
    @Column(columnDefinition = "TEXT") private String companyInfo;
    private UUID assessmentId;
    private UUID jobPositionId;
    @Column(nullable = false) private int passingScore;
    private boolean openToInternational;

    @Enumerated(EnumType.STRING) @Column(nullable = false) private JobOfferStatus status;
    @Column(nullable = false) private Instant postedAt;

    protected JobOfferEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getRecruiterId() { return recruiterId; }
    public void setRecruiterId(UUID recruiterId) { this.recruiterId = recruiterId; }
    public UUID getHiringContactId() { return hiringContactId; }
    public void setHiringContactId(UUID v) { this.hiringContactId = v; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getCompanyName() { return companyName; }
    public void setCompanyName(String v) { this.companyName = v; }
    public String getLocationCity() { return locationCity; }
    public void setLocationCity(String v) { this.locationCity = v; }
    public String getLocationCountry() { return locationCountry; }
    public void setLocationCountry(String v) { this.locationCountry = v; }
    public boolean isLocationRemote() { return locationRemote; }
    public void setLocationRemote(boolean v) { this.locationRemote = v; }
    public Double getSalaryMin() { return salaryMin; }
    public void setSalaryMin(Double v) { this.salaryMin = v; }
    public Double getSalaryMax() { return salaryMax; }
    public void setSalaryMax(Double v) { this.salaryMax = v; }
    public String getSalaryCurrency() { return salaryCurrency; }
    public void setSalaryCurrency(String v) { this.salaryCurrency = v; }
    public ContractType getContractType() { return contractType; }
    public void setContractType(ContractType v) { this.contractType = v; }
    public WorkplaceType getWorkplaceType() { return workplaceType; }
    public void setWorkplaceType(WorkplaceType v) { this.workplaceType = v; }
    public ExperienceLevel getExperienceLevel() { return experienceLevel; }
    public void setExperienceLevel(ExperienceLevel v) { this.experienceLevel = v; }
    public String getFieldOfWork() { return fieldOfWork; }
    public void setFieldOfWork(String v) { this.fieldOfWork = v; }
    public String getDescription() { return description; }
    public void setDescription(String v) { this.description = v; }
    public String getResponsibilities() { return responsibilities; }
    public void setResponsibilities(String v) { this.responsibilities = v; }
    public String getMinimumQualifications() { return minimumQualifications; }
    public void setMinimumQualifications(String v) { this.minimumQualifications = v; }
    public String getPreferredQualifications() { return preferredQualifications; }
    public void setPreferredQualifications(String v) { this.preferredQualifications = v; }
    public String getWhatWeOffer() { return whatWeOffer; }
    public void setWhatWeOffer(String v) { this.whatWeOffer = v; }
    public String getHowToApply() { return howToApply; }
    public void setHowToApply(String v) { this.howToApply = v; }
    public String getCompanyInfo() { return companyInfo; }
    public void setCompanyInfo(String v) { this.companyInfo = v; }
    public UUID getAssessmentId() { return assessmentId; }
    public void setAssessmentId(UUID v) { this.assessmentId = v; }
    public UUID getJobPositionId() { return jobPositionId; }
    public void setJobPositionId(UUID v) { this.jobPositionId = v; }
    public int getPassingScore() { return passingScore; }
    public void setPassingScore(int v) { this.passingScore = v; }
    public boolean isOpenToInternational() { return openToInternational; }
    public void setOpenToInternational(boolean v) { this.openToInternational = v; }
    public JobOfferStatus getStatus() { return status; }
    public void setStatus(JobOfferStatus v) { this.status = v; }
    public Instant getPostedAt() { return postedAt; }
    public void setPostedAt(Instant v) { this.postedAt = v; }
}
