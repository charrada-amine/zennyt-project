package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Match;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de matchs.
 */
public interface MatchRepository {

    Match save(Match match);

    Optional<Match> findById(UUID id);

    /** Match existant pour la paire (candidat, offre), s'il y en a un. */
    Optional<Match> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    void deleteById(UUID id);

    /** Matchs actifs du candidat connecté. */
    List<Match> findByCandidateId(UUID candidateId, int page, int size);

    long countByCandidateId(UUID candidateId);

    /** Matchs pour une offre (propriété déjà vérifiée par l'appelant). */
    List<Match> findByJobOfferId(UUID jobOfferId, int page, int size);

    long countByJobOfferId(UUID jobOfferId);
}
