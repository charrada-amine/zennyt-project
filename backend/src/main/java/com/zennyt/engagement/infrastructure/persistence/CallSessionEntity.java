package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.CallStatus;
import com.zennyt.engagement.domain.vo.CallType;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "call_sessions", schema = "engagement")
class CallSessionEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID conversationId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private CallType type;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private CallStatus status;
    @Column(nullable = false) private UUID initiatorId;
    @Column(nullable = false) private UUID counterpartId;
    @Column(nullable = false, columnDefinition = "TEXT") private String webrtcOffer;
    @Column(columnDefinition = "TEXT") private String webrtcAnswer;
    @Column(nullable = false) private Instant startedAt;
    private Instant endedAt;
    private Integer durationSeconds;
    @Version private long version;
    protected CallSessionEntity() {}
    CallSessionEntity(UUID id, UUID conversationId, CallType type, CallStatus status,
                      UUID initiatorId, UUID counterpartId, String webrtcOffer,
                      String webrtcAnswer, Instant startedAt, Instant endedAt,
                      Integer durationSeconds) {
        this.id = id; this.conversationId = conversationId; this.type = type;
        this.initiatorId = initiatorId; this.counterpartId = counterpartId;
        this.webrtcOffer = webrtcOffer; this.startedAt = startedAt;
        update(status, webrtcAnswer, endedAt, durationSeconds);
    }
    void update(CallStatus status, String answer, Instant endedAt, Integer duration) {
        this.status = status; this.webrtcAnswer = answer;
        this.endedAt = endedAt; this.durationSeconds = duration;
    }
    UUID getId() { return id; } UUID getConversationId() { return conversationId; }
    CallType getType() { return type; } CallStatus getStatus() { return status; }
    UUID getInitiatorId() { return initiatorId; } UUID getCounterpartId() { return counterpartId; }
    String getWebrtcOffer() { return webrtcOffer; } String getWebrtcAnswer() { return webrtcAnswer; }
    Instant getStartedAt() { return startedAt; } Instant getEndedAt() { return endedAt; }
    Integer getDurationSeconds() { return durationSeconds; }
}
