package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.CallStatus;
import com.zennyt.engagement.domain.vo.CallType;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public class CallSession {
    private final UUID id;
    private final UUID conversationId;
    private final CallType type;
    private CallStatus status;
    private final UUID initiatorId;
    private final UUID counterpartId;
    private final String webrtcOffer;
    private String webrtcAnswer;
    private final Instant startedAt;
    private Instant endedAt;
    private Integer durationSeconds;

    private CallSession(UUID id, UUID conversationId, CallType type, CallStatus status,
                        UUID initiatorId, UUID counterpartId, String webrtcOffer,
                        String webrtcAnswer, Instant startedAt, Instant endedAt,
                        Integer durationSeconds) {
        this.id = Objects.requireNonNull(id, "id");
        this.conversationId = Objects.requireNonNull(conversationId, "conversationId");
        this.type = Objects.requireNonNull(type, "type");
        this.status = Objects.requireNonNull(status, "status");
        this.initiatorId = Objects.requireNonNull(initiatorId, "initiatorId");
        this.counterpartId = Objects.requireNonNull(counterpartId, "counterpartId");
        if (initiatorId.equals(counterpartId)) throw new IllegalArgumentException("Participants identiques");
        if (webrtcOffer == null || webrtcOffer.isBlank()) throw new IllegalArgumentException("Offre WebRTC obligatoire");
        this.webrtcOffer = webrtcOffer;
        this.webrtcAnswer = webrtcAnswer;
        this.startedAt = Objects.requireNonNull(startedAt, "startedAt");
        this.endedAt = endedAt;
        this.durationSeconds = durationSeconds;
    }

    public static CallSession initiate(UUID conversationId, CallType type, UUID initiatorId,
                                       UUID counterpartId, String webrtcOffer) {
        return new CallSession(UUID.randomUUID(), conversationId, type, CallStatus.INITIATED,
            initiatorId, counterpartId, webrtcOffer, null, Instant.now(), null, null);
    }

    public static CallSession rehydrate(UUID id, UUID conversationId, CallType type,
                                        CallStatus status, UUID initiatorId, UUID counterpartId,
                                        String webrtcOffer, String webrtcAnswer, Instant startedAt,
                                        Instant endedAt, Integer durationSeconds) {
        return new CallSession(id, conversationId, type, status, initiatorId, counterpartId,
            webrtcOffer, webrtcAnswer, startedAt, endedAt, durationSeconds);
    }

    public void join(UUID actorId, String answer) {
        if (!counterpartId.equals(actorId)) throw new IllegalArgumentException("Seul le destinataire peut rejoindre");
        if (status != CallStatus.INITIATED) throw new IllegalStateException("Appel non rejoignable");
        if (answer == null || answer.isBlank()) throw new IllegalArgumentException("Réponse WebRTC obligatoire");
        status = CallStatus.IN_PROGRESS;
        webrtcAnswer = answer;
    }

    public void end(UUID actorId) {
        if (!isParticipant(actorId)) throw new IllegalArgumentException("Utilisateur extérieur à l'appel");
        if (status == CallStatus.ENDED) return;
        status = CallStatus.ENDED;
        endedAt = Instant.now();
        durationSeconds = Math.toIntExact(Math.max(0, endedAt.getEpochSecond() - startedAt.getEpochSecond()));
    }

    public boolean isParticipant(UUID actorId) {
        return initiatorId.equals(actorId) || counterpartId.equals(actorId);
    }

    public UUID id() { return id; }
    public UUID conversationId() { return conversationId; }
    public CallType type() { return type; }
    public CallStatus status() { return status; }
    public UUID initiatorId() { return initiatorId; }
    public UUID counterpartId() { return counterpartId; }
    public String webrtcOffer() { return webrtcOffer; }
    public String webrtcAnswer() { return webrtcAnswer; }
    public Instant startedAt() { return startedAt; }
    public Instant endedAt() { return endedAt; }
    public Integer durationSeconds() { return durationSeconds; }
}
