package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.vo.*;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO de réponse allégé pour les vues liste (contrat squad web, §3.4) — pas de
 * champs texte longs. {@code jobPositionId}/le fit score et
 * {@code applicantCount} restent présents au-delà de l'exemple minimal du
 * contrat : ce sont eux qui alimentent le deck de swipe candidat et le
 * référentiel de métiers, déjà en production. Plus de {@code passingScore} :
 * seuil de réussite fixe global désormais (contrat squad web §7.1).
 */
public record JobOfferSummaryResponse(
    UUID id, String title, String companyName, String city, String country,
    Double salaryMin, Double salaryMax,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    JobOfferStatus status, Instant postedAt,
    UUID jobPositionId, long applicantCount,
    Integer fitScore, Boolean goodFit, Integer softSkillScore, Integer cvMatchScore,
    Integer hardSkillScore, Boolean partialData
) {
    public static JobOfferSummaryResponse from(JobOffer o, String companyName, long applicantCount,
                                               com.zennyt.recruitment.domain.model.FitScore fitScore) {
        return new JobOfferSummaryResponse(
            o.id(), o.title(), companyName,
            o.location() != null ? o.location().city() : null,
            o.location() != null ? o.location().country() : null,
            o.salaryMin(), o.salaryMax(),
            o.contractType(), o.workplaceType(), o.experienceLevel(),
            o.status(), o.postedAt(),
            o.jobPositionId(), applicantCount,
            fitScore != null ? fitScore.score() : null,
            fitScore != null ? fitScore.goodFit() : null,
            fitScore != null ? fitScore.softSkillScore() : null,
            fitScore != null ? fitScore.cvMatchScore() : null,
            fitScore != null ? fitScore.hardSkillScore() : null,
            fitScore != null ? fitScore.partialData() : null
        );
    }
}
