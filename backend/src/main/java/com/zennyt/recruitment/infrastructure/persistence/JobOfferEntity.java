package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.*;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

/** Entité JPA pour la table job_offers. */
@Entity
// Index partiel idx_job_offers_position : db/schema-complements.sql.
@Table(name = "job_offers", schema = "recruitment", indexes = {
    @Index(name = "idx_job_offers_recruiter", columnList = "recruiter_id"),
    @Index(name = "idx_job_offers_status", columnList = "status"),
    @Index(name = "idx_job_offers_status_posted_at", columnList = "status, posted_at")})
@Check(name = "ck_job_offers_salary_currency", constraints = "salary_currency IN ('EUR', 'USD', 'GBP', 'MAD', 'TND')")
@Check(name = "ck_job_offers_salary_period", constraints = "salary_period IN ('MONTHLY', 'YEARLY')")
public class JobOfferEntity {

    @Id
    private UUID id;

    @Column(nullable = false) private UUID recruiterId;
    private UUID hiringContactId;
    @Column(nullable = false) private String title;
    private String locationCity;
    private String locationCountry;
    private Double salaryMin;
    private Double salaryMax;
    @ColumnDefault("'EUR'") @Column(name = "salary_currency", nullable = false, length = 3) private String salaryCurrency;
    @ColumnDefault("'MONTHLY'")
    @Enumerated(EnumType.STRING) @Column(name = "salary_period", nullable = false, length = 10) private SalaryPeriod salaryPeriod;

    @Enumerated(EnumType.STRING) @Column(nullable = false) private ContractType contractType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private WorkplaceType workplaceType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private ExperienceLevel experienceLevel;

    @Column(length = Length.LONG32) private String description;
    @Column(length = Length.LONG32) private String responsibilities;
    @Column(length = Length.LONG32) private String minimumQualifications;
    @Column(length = Length.LONG32) private String preferredQualifications;
    @Column(length = Length.LONG32) private String whatWeOffer;
    @Column(length = Length.LONG32) private String howToApply;
    private UUID assessmentId;
    @Column(name = "job_position_id") private UUID jobPositionId;

    /** Clé étrangère {@code recruitment.job_positions(id)} ; lecture seule, écrite via {@link #jobPositionId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_position_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "job_offers_job_position_id_fkey"))
    private JobPositionEntity jobPosition;
    @ColumnDefault("false") private boolean openToInternational;

    @Enumerated(EnumType.STRING) @Column(nullable = false) private JobOfferStatus status;
    @Column(nullable = false) private Instant postedAt;
    @Column(nullable = false) private Instant updatedAt;

    protected JobOfferEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getRecruiterId() { return recruiterId; }
    public void setRecruiterId(UUID recruiterId) { this.recruiterId = recruiterId; }
    public UUID getHiringContactId() { return hiringContactId; }
    public void setHiringContactId(UUID v) { this.hiringContactId = v; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getLocationCity() { return locationCity; }
    public void setLocationCity(String v) { this.locationCity = v; }
    public String getLocationCountry() { return locationCountry; }
    public void setLocationCountry(String v) { this.locationCountry = v; }
    public Double getSalaryMin() { return salaryMin; }
    public void setSalaryMin(Double v) { this.salaryMin = v; }
    public Double getSalaryMax() { return salaryMax; }
    public void setSalaryMax(Double v) { this.salaryMax = v; }
    public String getSalaryCurrency() { return salaryCurrency; }
    public void setSalaryCurrency(String v) { this.salaryCurrency = v; }
    public SalaryPeriod getSalaryPeriod() { return salaryPeriod; }
    public void setSalaryPeriod(SalaryPeriod v) { this.salaryPeriod = v; }
    public ContractType getContractType() { return contractType; }
    public void setContractType(ContractType v) { this.contractType = v; }
    public WorkplaceType getWorkplaceType() { return workplaceType; }
    public void setWorkplaceType(WorkplaceType v) { this.workplaceType = v; }
    public ExperienceLevel getExperienceLevel() { return experienceLevel; }
    public void setExperienceLevel(ExperienceLevel v) { this.experienceLevel = v; }
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
    public UUID getAssessmentId() { return assessmentId; }
    public void setAssessmentId(UUID v) { this.assessmentId = v; }
    public UUID getJobPositionId() { return jobPositionId; }
    public void setJobPositionId(UUID v) { this.jobPositionId = v; }
    public boolean isOpenToInternational() { return openToInternational; }
    public void setOpenToInternational(boolean v) { this.openToInternational = v; }
    public JobOfferStatus getStatus() { return status; }
    public void setStatus(JobOfferStatus v) { this.status = v; }
    public Instant getPostedAt() { return postedAt; }
    public void setPostedAt(Instant v) { this.postedAt = v; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant v) { this.updatedAt = v; }
}
