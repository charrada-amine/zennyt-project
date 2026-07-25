package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Match — match mutuel entre un candidat et un recruteur pour une offre.
 *
 * <p>Un match est créé lorsque les deux parties ont swipé RIGHT mutuellement.
 * Binaire (contrat squad web §6.1) : il existe ou n'existe pas, pas de statut
 * intermédiaire — aucun concept de scoring/expiration n'a jamais été conçu.
 */
public class Match extends AggregateRoot {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final UUID recruiterId;
    private final Instant matchedAt;

    private Match(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId, Instant matchedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.recruiterId = recruiterId;
        this.matchedAt = matchedAt;
    }

    /** Fabrique : crée un match et enregistre l'événement. */
    public static Match create(UUID candidateId, UUID jobOfferId, UUID recruiterId, String jobTitle) {
        Match match = new Match(UUID.randomUUID(), candidateId, jobOfferId, recruiterId, Instant.now());
        match.registerEvent(MatchCreatedEvent.of(match.id, candidateId, jobOfferId, recruiterId, jobTitle));
        return match;
    }

    /** Reconstruction depuis la persistance. */
    public static Match rehydrate(UUID id, UUID candidateId, UUID jobOfferId, UUID recruiterId,
                                  Instant matchedAt) {
        return new Match(id, candidateId, jobOfferId, recruiterId, matchedAt);
    }

    public UUID id() { return id; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID recruiterId() { return recruiterId; }
    public Instant matchedAt() { return matchedAt; }
}
