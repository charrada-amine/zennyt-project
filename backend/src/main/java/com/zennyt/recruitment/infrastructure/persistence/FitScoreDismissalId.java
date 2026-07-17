package com.zennyt.recruitment.infrastructure.persistence;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class FitScoreDismissalId implements Serializable {
    private UUID recruiterId;
    private UUID candidateId;
    private UUID jobOfferId;

    public FitScoreDismissalId() {}
    public FitScoreDismissalId(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        this.recruiterId = recruiterId;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
    }

    @Override public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof FitScoreDismissalId that)) return false;
        return Objects.equals(recruiterId, that.recruiterId)
            && Objects.equals(candidateId, that.candidateId)
            && Objects.equals(jobOfferId, that.jobOfferId);
    }
    @Override public int hashCode() { return Objects.hash(recruiterId, candidateId, jobOfferId); }
}
