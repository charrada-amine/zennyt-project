package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.SwipeRecordedEvent;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Swipe — mécanique bidirectionnelle (candidat sur offre, recruteur sur candidat).
 *
 * <p>État courant, pas un historique : un seul swipe actif par
 * {@code (jobOfferId, candidateId, side)}. Changer d'avis exige un undo
 * explicite (delete) suivi d'un nouveau swipe — jamais de réécriture
 * silencieuse d'un swipe existant (contrat squad web §5.1).
 * {@code recruiterId} n'est jamais stocké ici ; il se dérive toujours de
 * {@code jobOffer.recruiterId()}.
 */
public class Swipe extends AggregateRoot {

    private final UUID id;
    private final UUID jobOfferId;
    private final UUID candidateId;
    private final SwipeSide side;
    private final SwipeDirection direction;
    private final Instant createdAt;

    private Swipe(UUID id, UUID jobOfferId, UUID candidateId, SwipeSide side,
                  SwipeDirection direction, Instant createdAt) {
        this.id = id;
        this.jobOfferId = jobOfferId;
        this.candidateId = candidateId;
        this.side = side;
        this.direction = direction;
        this.createdAt = createdAt;
    }

    /** Enregistrer un swipe et émettre l'événement correspondant. */
    public static Swipe record(UUID jobOfferId, UUID candidateId, SwipeSide side, SwipeDirection direction) {
        Swipe swipe = new Swipe(UUID.randomUUID(), jobOfferId, candidateId, side, direction, Instant.now());
        swipe.registerEvent(SwipeRecordedEvent.of(swipe.id, jobOfferId, candidateId, side, direction));
        return swipe;
    }

    /** Reconstruction depuis la persistance. */
    public static Swipe rehydrate(UUID id, UUID jobOfferId, UUID candidateId, SwipeSide side,
                                  SwipeDirection direction, Instant createdAt) {
        return new Swipe(id, jobOfferId, candidateId, side, direction, createdAt);
    }

    /** Le côté opposé — celui dont le swipe RIGHT réciproque formerait un match. */
    public SwipeSide mutualSide() {
        return side == SwipeSide.CANDIDATE ? SwipeSide.RECRUITER : SwipeSide.CANDIDATE;
    }

    public UUID id() { return id; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID candidateId() { return candidateId; }
    public SwipeSide side() { return side; }
    public SwipeDirection direction() { return direction; }
    public Instant createdAt() { return createdAt; }
}
