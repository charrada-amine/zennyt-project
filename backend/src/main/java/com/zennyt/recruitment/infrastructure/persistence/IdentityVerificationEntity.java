package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.IdentityVerificationStatus;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "identity_verifications", schema = "recruitment")
public class IdentityVerificationEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID requestedByRecruiterId;
    @Column(nullable = false) private UUID targetCandidateId;
    private UUID jobOfferId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private IdentityVerificationStatus status;
    @Column(nullable = false) private Instant requestedAt;
    private Instant resolvedAt;

    protected IdentityVerificationEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getRequestedByRecruiterId() { return requestedByRecruiterId; }
    public void setRequestedByRecruiterId(UUID v) { this.requestedByRecruiterId = v; }
    public UUID getTargetCandidateId() { return targetCandidateId; }
    public void setTargetCandidateId(UUID v) { this.targetCandidateId = v; }
    public UUID getJobOfferId() { return jobOfferId; }
    public void setJobOfferId(UUID v) { this.jobOfferId = v; }
    public IdentityVerificationStatus getStatus() { return status; }
    public void setStatus(IdentityVerificationStatus v) { this.status = v; }
    public Instant getRequestedAt() { return requestedAt; }
    public void setRequestedAt(Instant v) { this.requestedAt = v; }
    public Instant getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(Instant v) { this.resolvedAt = v; }
}
