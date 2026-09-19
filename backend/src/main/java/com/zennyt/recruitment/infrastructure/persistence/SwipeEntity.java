package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "swipes", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(name = "uq_swipes_pair_side", columnNames = {"job_offer_id", "candidate_id", "side"}),
    indexes = {
        @Index(name = "idx_swipes_candidate", columnList = "candidate_id"),
        @Index(name = "idx_swipes_job_offer", columnList = "job_offer_id")})
public class SwipeEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID candidateId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private SwipeSide side;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 10) private SwipeDirection direction;
    @Column(nullable = false) private Instant createdAt;

    protected SwipeEntity() {}
    public SwipeEntity(UUID id, UUID jobOfferId, UUID candidateId, SwipeSide side,
                       SwipeDirection direction, Instant createdAt) {
        this.id = id; this.jobOfferId = jobOfferId; this.candidateId = candidateId;
        this.side = side; this.direction = direction; this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getCandidateId() { return candidateId; }
    public SwipeSide getSide() { return side; }
    public SwipeDirection getDirection() { return direction; }
    public Instant getCreatedAt() { return createdAt; }
}
