package com.zennyt.recruitment.infrastructure.persistence;

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
    @Column(nullable = false) private Instant matchedAt;

    protected MatchEntity() {}
    public MatchEntity(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId, Instant matchedAt) {
        this.id = id; this.candidateId = candidateId; this.jobOfferId = jobOfferId;
        this.recruiterId = recruiterId;
        this.matchedAt = matchedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getRecruiterId() { return recruiterId; }
    public Instant getMatchedAt() { return matchedAt; }
}
