package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.MatchStatus;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "matches", schema = "recruitment")
public class MatchEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID recruiterId;
    private String jobOfferTitle;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private MatchStatus status;
    @Column(nullable = false) private Instant matchedAt;

    protected MatchEntity() {}
    public MatchEntity(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId,
                       String jobOfferTitle, MatchStatus status, Instant matchedAt) {
        this.id = id; this.candidateId = candidateId; this.jobOfferId = jobOfferId;
        this.recruiterId = recruiterId; this.jobOfferTitle = jobOfferTitle;
        this.status = status; this.matchedAt = matchedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getRecruiterId() { return recruiterId; }
    public String getJobOfferTitle() { return jobOfferTitle; }
    public MatchStatus getStatus() { return status; }
    public Instant getMatchedAt() { return matchedAt; }
}
