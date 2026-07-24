package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository d'offres d'emploi.
 */
public interface JobOfferRepository {

    JobOffer save(JobOffer jobOffer);

    Optional<JobOffer> findById(UUID id);

    void deleteById(UUID id);

    /**
     * Offres du recruteur connecté, filtrées par statut optionnel.
     * @param sort {@code "champ,direction"} (ex. {@code "postedAt,desc"}) — {@code null}/vide
     *             ou champ non reconnu retombe sur le tri par défaut (contrat squad web §1/§3.2).
     */
    List<JobOffer> findByRecruiterId(UUID recruiterId, JobOfferStatus status, String sort, int page, int size);

    long countByRecruiterId(UUID recruiterId, JobOfferStatus status);

    /** Une offre référence-t-elle encore cette évaluation ? (intégrité avant suppression) */
    boolean existsByAssessmentId(UUID assessmentId);

    /** Ids des offres référençant encore cette évaluation. */
    List<UUID> findIdsByAssessmentId(UUID assessmentId);

    /** Nombre d'offres référençant chaque évaluation (vue liste recruteur). */
    java.util.Map<UUID, Long> countByAssessmentIds(List<UUID> assessmentIds);

    /** Recherche plein texte avec filtres (vue candidat, offres ACTIVE uniquement). */
    List<JobOffer> search(String query, String location, String contractType,
                          String workplaceType, String experienceLevel, String fieldOfWork,
                          Double salaryMin, Double salaryMax, String sort, int page, int size);

    long countSearch(String query, String location, String contractType,
                     String workplaceType, String experienceLevel, String fieldOfWork,
                     Double salaryMin, Double salaryMax);

    /** Fil d'offres recommandées pour un candidat (triées par fit score). */
    List<JobOffer> findFeedForCandidate(UUID candidateId, int page, int size);

    long countFeedForCandidate(UUID candidateId);

    /** Offre + indicateur "le recruteur a déjà swipé RIGHT sur ce candidat pour cette offre". */
    record MatchingDeckOffer(JobOffer offer, boolean recruiterAlreadyInterested) {}

    /**
     * Deck de swipe candidat (contrat squad web §5.5) : offres ACTIVE, exclut celles
     * déjà swipées LEFT ou déjà matchées, priorité aux offres où le recruteur a déjà
     * swipé RIGHT sur ce candidat.
     */
    List<MatchingDeckOffer> findMatchingDeckForCandidate(UUID candidateId, int page, int size);

    long countMatchingDeckForCandidate(UUID candidateId);
}
