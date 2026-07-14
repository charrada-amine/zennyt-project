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

    /** Offres du recruteur connecté, filtrées par statut optionnel. */
    List<JobOffer> findByRecruiterId(UUID recruiterId, JobOfferStatus status, int page, int size);

    long countByRecruiterId(UUID recruiterId, JobOfferStatus status);

    /** Une offre référence-t-elle encore cette évaluation ? (intégrité avant suppression) */
    boolean existsByAssessmentId(UUID assessmentId);

    /** Recherche plein texte avec filtres (vue candidat, offres ACTIVE uniquement). */
    List<JobOffer> search(String query, String location, String contractType,
                          String workplaceType, String experienceLevel, String fieldOfWork,
                          Double salaryMin, Double salaryMax, int page, int size);

    long countSearch(String query, String location, String contractType,
                     String workplaceType, String experienceLevel, String fieldOfWork,
                     Double salaryMin, Double salaryMax);

    /** Fil d'offres recommandées pour un candidat (triées par fit score). */
    List<JobOffer> findFeedForCandidate(UUID candidateId, int page, int size);

    long countFeedForCandidate(UUID candidateId);
}
