package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.CallStatus;
import com.zennyt.engagement.domain.vo.CallType;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "call_sessions", schema = "engagement",
    indexes = @Index(name = "idx_engagement_calls_conversation", columnList = "conversation_id, started_at DESC"))
class CallSessionEntity {
    @Id private UUID id;
    @Column(name = "conversation_id", nullable = false) private UUID conversationId;
    /** Clé étrangère {@code engagement.conversations(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #conversationId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "call_sessions_conversation_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ConversationEntity conversation;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private CallType type;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private CallStatus status;
    @Column(nullable = false) private UUID initiatorId;
    @Column(nullable = false) private UUID counterpartId;
    @Column(nullable = false, length = Length.LONG32) private String webrtcOffer;
    @Column(length = Length.LONG32) private String webrtcAnswer;
    @Column(nullable = false) private Instant startedAt;
    private Instant endedAt;
    private Integer durationSeconds;
    @Version @ColumnDefault("0") private long version;
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
