package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.SwipeRecordedEvent;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Swipe — mécanique bidirectionnelle (candidat sur offre, recruteur sur candidat).
 *
 * <p>Quel que soit le côté qui swipe, le swipe est normalisé autour de la paire
 * {@code (candidateId, jobOfferId)} : c'est cette paire qui permet d'apparier les
 * deux swipes opposés et de détecter un match mutuel. Concrètement :
 * <ul>
 *   <li>candidat → JOB_OFFER : {@code candidateId = actorId}, {@code jobOfferId = targetId}</li>
 *   <li>recruteur → CANDIDATE : {@code candidateId = targetId}, {@code jobOfferId} fourni par le recruteur</li>
 * </ul>
 *
 * <p>Si le swipe crée un match mutuel, un {@code MatchCreatedEvent} est publié
 * par le use case (pas par l'agrégat lui-même, car la détection de mutualité
 * nécessite de consulter le repository).
 */
public class Swipe extends AggregateRoot {

    public static final String TARGET_JOB_OFFER = "JOB_OFFER";
    public static final String TARGET_CANDIDATE = "CANDIDATE";

    private final UUID id;
    private final UUID actorId;
    private final UUID targetId;
    private final String targetType; // "JOB_OFFER" ou "CANDIDATE"
    private final UUID candidateId;  // côté candidat de la paire, quel que soit l'acteur
    private final UUID jobOfferId;   // offre concernée, quel que soit l'acteur
    private final SwipeDirection direction;
    private final Instant swipedAt;

    private Swipe(UUID id, UUID actorId, UUID targetId, String targetType,
                  UUID candidateId, UUID jobOfferId, SwipeDirection direction) {
        this.id = id;
        this.actorId = actorId;
        this.targetId = targetId;
        this.targetType = targetType;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.direction = direction;
        this.swipedAt = Instant.now();
    }

    /**
     * Enregistrer un swipe et émettre l'événement correspondant.
     *
     * <p>Normalise la paire {@code (candidateId, jobOfferId)} à partir de l'acteur,
     * de la cible et du type de cible. Le recruteur doit fournir {@code jobOfferId}
     * (l'offre pour laquelle il considère le candidat).
     */
    public static Swipe record(UUID actorId, UUID targetId, String targetType,
                               UUID jobOfferId, SwipeDirection direction) {
        UUID candidateId;
        UUID resolvedOfferId;
        if (TARGET_JOB_OFFER.equals(targetType)) {
            candidateId = actorId;
            resolvedOfferId = targetId;
        } else if (TARGET_CANDIDATE.equals(targetType)) {
            if (jobOfferId == null) {
                throw new IllegalArgumentException(
                    "jobOfferId est requis lorsqu'un recruteur swipe un candidat");
            }
            candidateId = targetId;
            resolvedOfferId = jobOfferId;
        } else {
            throw new IllegalArgumentException("targetType inconnu : " + targetType);
        }
        Swipe swipe = new Swipe(UUID.randomUUID(), actorId, targetId, targetType,
            candidateId, resolvedOfferId, direction);
        swipe.registerEvent(SwipeRecordedEvent.of(swipe.id, actorId, targetId, targetType, direction));
        return swipe;
    }

    /** Reconstruction depuis la persistance. */
    public static Swipe rehydrate(UUID id, UUID actorId, UUID targetId, String targetType,
                                  UUID candidateId, UUID jobOfferId,
                                  SwipeDirection direction, Instant swipedAt) {
        return new Swipe(id, actorId, targetId, targetType, candidateId, jobOfferId, direction);
    }

    /** Type de cible du swipe opposé qui formerait un match mutuel avec celui-ci. */
    public String mutualTargetType() {
        return TARGET_JOB_OFFER.equals(targetType) ? TARGET_CANDIDATE : TARGET_JOB_OFFER;
    }

    public UUID id() { return id; }
    public UUID actorId() { return actorId; }
    public UUID targetId() { return targetId; }
    public String targetType() { return targetType; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public SwipeDirection direction() { return direction; }
    public Instant swipedAt() { return swipedAt; }
}
