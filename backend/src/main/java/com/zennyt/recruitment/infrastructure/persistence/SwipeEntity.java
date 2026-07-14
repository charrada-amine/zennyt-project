package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.SwipeDirection;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "swipes", schema = "recruitment")
public class SwipeEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID actorId;
    @Column(nullable = false) private UUID targetId;
    @Column(nullable = false) private String targetType;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID jobOfferId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private SwipeDirection direction;
    @Column(nullable = false) private Instant swipedAt;

    protected SwipeEntity() {}
    public SwipeEntity(UUID id, UUID actorId, UUID targetId, String targetType,
                       UUID candidateId, UUID jobOfferId, SwipeDirection direction, Instant swipedAt) {
        this.id = id; this.actorId = actorId; this.targetId = targetId;
        this.targetType = targetType; this.candidateId = candidateId; this.jobOfferId = jobOfferId;
        this.direction = direction; this.swipedAt = swipedAt;
    }

    public UUID getId() { return id; }
    public UUID getActorId() { return actorId; }
    public UUID getTargetId() { return targetId; }
    public String getTargetType() { return targetType; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public SwipeDirection getDirection() { return direction; }
    public Instant getSwipedAt() { return swipedAt; }
}
