package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "job_opportunity_offers", schema = "recruitment")
public class JobOpportunityOfferEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID recruiterId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID jobOfferId;
    private String title;
    private Double salaryMin;
    private Double salaryMax;
    private String salaryCurrency;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private JobOpportunityStatus status;
    private boolean otpVerified;
    @Column(nullable = false) private Instant sentAt;
    private Instant respondedAt;

    protected JobOpportunityOfferEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getRecruiterId() { return recruiterId; }
    public void setRecruiterId(UUID v) { this.recruiterId = v; }
    public UUID getCandidateId() { return candidateId; }
    public void setCandidateId(UUID v) { this.candidateId = v; }
    public UUID getJobOfferId() { return jobOfferId; }
    public void setJobOfferId(UUID v) { this.jobOfferId = v; }
    public String getTitle() { return title; }
    public void setTitle(String v) { this.title = v; }
    public Double getSalaryMin() { return salaryMin; }
    public void setSalaryMin(Double v) { this.salaryMin = v; }
    public Double getSalaryMax() { return salaryMax; }
    public void setSalaryMax(Double v) { this.salaryMax = v; }
    public String getSalaryCurrency() { return salaryCurrency; }
    public void setSalaryCurrency(String v) { this.salaryCurrency = v; }
    public JobOpportunityStatus getStatus() { return status; }
    public void setStatus(JobOpportunityStatus v) { this.status = v; }
    public boolean isOtpVerified() { return otpVerified; }
    public void setOtpVerified(boolean v) { this.otpVerified = v; }
    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant v) { this.sentAt = v; }
    public Instant getRespondedAt() { return respondedAt; }
    public void setRespondedAt(Instant v) { this.respondedAt = v; }
}
