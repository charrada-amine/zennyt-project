package com.zennyt.analytics.domain.repository;

import java.util.Map;
import java.util.UUID;

/** Lecture du read-model Analytics (agrégats pour les tableaux de bord). */
public interface AnalyticsReadRepository {

    /** Nombre d'activités candidat d'un type donné (INTERESTED/MATCHED/TEST_COMPLETED). */
    long countCandidateActivity(UUID candidateId, String kind);

    /** Répartition des activités d'un candidat par type. */
    Map<String, Long> candidateActivityByKind(UUID candidateId);

    long countOffersByRecruiter(UUID recruiterId);

    long countActiveOffersByRecruiter(UUID recruiterId);

    /** Candidatures (INTERESTED) reçues sur les offres d'un recruteur. */
    long countApplicationsForRecruiter(UUID recruiterId);

    /** Candidatures (INTERESTED) reçues sur une offre. */
    long countApplicationsForOffer(UUID jobOfferId);

    /** Recruteur propriétaire d'une offre du read-model, si elle y est projetée. */
    java.util.Optional<UUID> findRecruiterIdForOffer(UUID jobOfferId);
}
