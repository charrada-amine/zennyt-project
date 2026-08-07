package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.RecruitmentActor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecruitmentActorRepository {
    Optional<RecruitmentActor> findById(UUID publicUserId);
    /** Variante par lot de {@link #findById} — une seule requête pour tout un lot de recalcul. */
    List<RecruitmentActor> findByIds(List<UUID> publicUserIds);
    RecruitmentActor save(RecruitmentActor actor);

    /** Candidat + indicateur "ce candidat a déjà swipé RIGHT sur cette offre". */
    record MatchingDeckCandidate(RecruitmentActor actor, boolean candidateAlreadyInterested) {}

    /**
     * Deck de swipe recruteur (contrat squad web §5.5) : candidats/étudiants actifs,
     * exclut ceux déjà swipés LEFT ou déjà matchés pour cette offre, priorité à ceux
     * ayant déjà swipé RIGHT sur cette offre.
     */
    List<MatchingDeckCandidate> findMatchingDeckForJobOffer(UUID jobOfferId, int page, int size);

    long countMatchingDeckForJobOffer(UUID jobOfferId);
}
