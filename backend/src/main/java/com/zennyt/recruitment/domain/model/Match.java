package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.recruitment.domain.vo.MatchStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Match — match mutuel entre un candidat et un recruteur pour une offre.
 *
 * <p>Un match est créé lorsque les deux parties ont swipé LIKE mutuellement.
 */
public class Match extends AggregateRoot {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final UUID recruiterId;
    private String jobOfferTitle;
    private MatchStatus status;
    private final Instant matchedAt;

    private Match(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId, String jobOfferTitle) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.recruiterId = recruiterId;
        this.jobOfferTitle = jobOfferTitle;
        this.status = MatchStatus.ACTIVE;
        this.matchedAt = Instant.now();
    }

    /** Fabrique : crée un match et enregistre l'événement. */
    public static Match create(UUID candidateId, UUID jobOfferId, UUID recruiterId, String jobOfferTitle) {
        Match match = new Match(UUID.randomUUID(), candidateId, jobOfferId, recruiterId, jobOfferTitle);
        match.registerEvent(MatchCreatedEvent.of(match.id, candidateId, jobOfferId, recruiterId));
        return match;
    }

    /** Reconstruction depuis la persistance. */
    public static Match rehydrate(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId,
                                  String jobOfferTitle, MatchStatus status, Instant matchedAt) {
        Match match = new Match(id, candidateId, jobOfferId, recruiterId, jobOfferTitle);
        match.status = status;
        return match;
    }

    public UUID id() { return id; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID recruiterId() { return recruiterId; }
    public String jobOfferTitle() { return jobOfferTitle; }
    public MatchStatus status() { return status; }
    public Instant matchedAt() { return matchedAt; }
}
