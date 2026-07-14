package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.vo.SwipeDirection;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de swipes.
 */
public interface SwipeRepository {

    Swipe save(Swipe swipe);

    Optional<Swipe> findById(UUID id);

    /** Swipe existant d'un acteur sur la paire (candidat, offre) — clé d'upsert. */
    Optional<Swipe> findByActorAndPair(UUID actorId, UUID candidateId, UUID jobOfferId);

    void deleteById(UUID id);

    /** Ids des cibles déjà swipées par un acteur, optionnellement scopées à une offre. */
    List<UUID> findTargetIdsByActorId(UUID actorId, UUID jobOfferId);

    /** Vérifie si un acteur a déjà swipé ce candidat pour cette offre (clé de dédup). */
    boolean existsByActorIdAndCandidateIdAndJobOfferId(UUID actorId, UUID candidateId, UUID jobOfferId);

    /**
     * Recherche le swipe opposé pour détecter un match mutuel.
     *
     * <p>L'appariement se fait sur la paire {@code (candidateId, jobOfferId)} et le
     * type de cible <b>opposé</b> ({@code mutualTargetType}). Ce dernier garantit
     * que l'on ne réapparie pas le swipe que l'on vient d'enregistrer : un swipe
     * candidat (type JOB_OFFER) cherche un swipe recruteur (type CANDIDATE) et
     * inversement.
     *
     * <p>Ex : le candidat a swipé LIKE sur l'offre → on cherche si le recruteur a
     * swipé LIKE sur ce candidat pour la même offre.
     */
    Optional<Swipe> findMutualLike(UUID candidateId, UUID jobOfferId,
                                   String mutualTargetType, SwipeDirection direction);
}
